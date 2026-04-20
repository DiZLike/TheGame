import numpy as np
import scipy.io.wavfile as wav
from scipy import signal
from scipy.ndimage import gaussian_filter1d
from scipy import interpolate
import sys
import os

def wav_to_nes_ultraclean(input_path, output_path, preserve_timbre=True):
    """
    Преобразует WAV в звук NES с МИНИМАЛЬНЫМИ артефактами.
    Оптимизированная версия без хруста, треска и шума.
    """
    
    # Константы NES
    NES_RATE = 33144
    CPU_RATE = 1789773
    OUTPUT_RATE = 44100
    
    # === ЧТЕНИЕ И ПОДГОТОВКА ===
    rate, data = wav.read(input_path)
    
    # Конвертация в моно
    if len(data.shape) > 1:
        data = data.mean(axis=1).astype(np.float64)
    else:
        data = data.astype(np.float64)
    
    # Нормализация с запасом для избежания клиппинга
    peak = np.max(np.abs(data))
    if peak > 0:
        data = data / peak * 0.8
    
    duration = len(data) / rate
    nes_len = int(duration * NES_RATE)
    
    # === ВЫСОКОКАЧЕСТВЕННЫЙ РЕСЕМПЛИНГ ===
    resampled = signal.resample(data, nes_len)
    
    # Легкая фильтрация перед DPCM для удаления высоких частот
    b_pre, a_pre = signal.butter(4, 8000 / (NES_RATE/2), btype='low')
    resampled = signal.filtfilt(b_pre, a_pre, resampled)
    
    # Приводим к диапазону 0..1 для DPCM
    resampled = (resampled - resampled.min()) / (resampled.max() - resampled.min())
    resampled = np.clip(resampled, 0.05, 0.95)
    
    # === ТАБЛИЦА ЦАП NES ===
    dac_standard = np.array([
        0.000, 0.008, 0.016, 0.027, 0.041, 0.058, 0.078, 0.101,
        0.127, 0.156, 0.188, 0.223, 0.261, 0.302, 0.346, 0.393,
        0.443, 0.496, 0.552, 0.611, 0.673, 0.738, 0.806, 0.877,
        0.951, 1.028, 1.108, 1.191, 1.277, 1.366, 1.458, 1.553,
        1.651, 1.752, 1.856, 1.963, 2.073, 2.186, 2.302, 2.421,
        2.543, 2.668, 2.796, 2.927, 3.061, 3.198, 3.338, 3.481,
        3.627, 3.776, 3.928, 4.083, 4.241, 4.402, 4.566, 4.733,
        4.903, 5.076, 5.252, 5.431, 5.613, 5.798, 5.986, 6.177,
        6.371, 6.568, 6.768, 6.971, 7.177, 7.386, 7.598, 7.813,
        8.031, 8.252, 8.476, 8.703, 8.933, 9.166, 9.402, 9.641,
        9.883, 10.128, 10.376, 10.627, 10.881, 11.138, 11.398, 11.661,
        11.927, 12.196, 12.468, 12.743, 13.021, 13.302, 13.586, 13.873,
        14.163, 14.456, 14.752, 15.051, 15.353, 15.658, 15.966, 16.277,
        16.591, 16.908, 17.228, 17.551, 17.877, 18.206, 18.538, 18.873,
        19.211, 19.552, 19.896, 20.243, 20.593, 20.946, 21.302, 21.661,
        22.023, 22.388, 22.756, 23.127, 23.501, 23.878, 24.258, 24.641,
        25.027, 25.416, 25.808, 26.203, 26.601, 27.002, 27.406, 27.813
    ])
    dac_lut = dac_standard / dac_standard[-1]
    
    # Интерполяция DAC для сглаживания ступенек
    x_orig = np.linspace(0, 1, len(dac_lut))
    x_smooth = np.linspace(0, 1, 1024)
    dac_smooth = np.interp(x_smooth, x_orig, dac_lut)
    
    # === DPCM КОДИРОВАНИЕ ===
    dpcm_bits = np.zeros(nes_len, dtype=np.uint8)
    current_val = 0.5
    base_step = 1.0 / 64.0
    
    for i in range(nes_len):
        sample = resampled[i]
        
        if sample >= current_val:
            dpcm_bits[i] = 1
            current_val += base_step
        else:
            dpcm_bits[i] = 0
            current_val -= base_step
        
        if current_val > 1.0:
            current_val = 1.0 - (current_val - 1.0) * 0.1
        elif current_val < 0.0:
            current_val = abs(current_val) * 0.1
        
        current_val = np.clip(current_val, 0.0, 1.0)
    
    # === ДЕКОДИРОВАНИЕ ===
    decoded = np.zeros(nes_len, dtype=np.float64)
    current_val = 0.5
    step = 1.0 / 64.0
    
    for i in range(nes_len):
        if dpcm_bits[i] == 1:
            current_val += step
        else:
            current_val -= step
        
        current_val = np.clip(current_val, 0.0, 1.0)
        dac_index = int(current_val * 1023)
        decoded[i] = dac_smooth[dac_index]
    
    # === ФИЛЬТРАЦИЯ ===
    decoded = decoded - np.mean(decoded)
    decoded = gaussian_filter1d(decoded, sigma=0.6, mode='nearest')
    
    b1, a1 = signal.butter(6, 12000 / (NES_RATE/2), btype='low')
    decoded = signal.filtfilt(b1, a1, decoded)
    
    b2, a2 = signal.butter(4, 14000 / (NES_RATE/2), btype='low')
    decoded = signal.filtfilt(b2, a2, decoded)
    
    notch_freq = NES_RATE / 4
    b_notch, a_notch = signal.iirnotch(notch_freq, 20, NES_RATE)
    decoded = signal.filtfilt(b_notch, a_notch, decoded)
    
    if preserve_timbre:
        decoded = np.tanh(decoded * 1.1)
    else:
        decoded = gaussian_filter1d(decoded, sigma=0.3, mode='nearest')
    
    # === РЕСЕМПЛИНГ НА 44100 ГЦ ===
    output_len = int(duration * OUTPUT_RATE)
    
    tck = interpolate.splrep(
        np.linspace(0, duration, nes_len), 
        decoded, 
        s=0
    )
    final_audio = interpolate.splev(
        np.linspace(0, duration, output_len), 
        tck, 
        der=0
    )
    
    b_final, a_final = signal.butter(8, 15000 / (OUTPUT_RATE/2), btype='low')
    final_audio = signal.filtfilt(b_final, a_final, final_audio)
    
    # === НОРМАЛИЗАЦИЯ ===
    peak_out = np.max(np.abs(final_audio))
    if peak_out > 0:
        final_audio = final_audio / peak_out * 0.95
    
    fade_len = min(512, len(final_audio) // 10)
    fade_in = np.linspace(0, 1, fade_len)
    fade_out = np.linspace(1, 0, fade_len)
    final_audio[:fade_len] *= fade_in
    final_audio[-fade_len:] *= fade_out
    
    final_audio_int16 = np.clip(final_audio * 32767, -32768, 32767).astype(np.int16)
    wav.write(output_path, OUTPUT_RATE, final_audio_int16)
    
    print(f"✅ NES Ultraclean сохранен: {output_path}")
    print(f"📊 Длительность: {duration:.2f} сек")
    print(f"🎵 Режим: {'NES-окраска' if preserve_timbre else 'Максимальная чистота'}")
    
    return output_path


def wav_to_nes_style_enhanced(input_path, output_path, revision='standard', 
                              add_artifacts=True, export_mode='safe',
                              quality='high', disable_dpcm_smoothing=False):
    """
    Преобразует WAV в звук, максимально похожий на DPCM-канал NES.
    """
    
    NES_RATE = 33144
    CPU_RATE = 1789773
    
    quality_settings = {
        'high': {
            'pre_filter_cutoff': 8000,
            'post_filter_cutoff': 12000,
            'smoothing_sigma': 0.8,
            'noise_reduction': 0.7,
            'anti_aliasing': True
        },
        'medium': {
            'pre_filter_cutoff': 8000,
            'post_filter_cutoff': 12000,
            'smoothing_sigma': 0.5,
            'noise_reduction': 0.5,
            'anti_aliasing': True
        },
        'low': {
            'pre_filter_cutoff': 8000,
            'post_filter_cutoff': 12000,
            'smoothing_sigma': 0.3,
            'noise_reduction': 0.3,
            'anti_aliasing': False
        }
    }
    
    qs = quality_settings[quality]
    
    def get_dac_lut(revision_type):
        dac_standard = np.array([
            0.000, 0.008, 0.016, 0.027, 0.041, 0.058, 0.078, 0.101,
            0.127, 0.156, 0.188, 0.223, 0.261, 0.302, 0.346, 0.393,
            0.443, 0.496, 0.552, 0.611, 0.673, 0.738, 0.806, 0.877,
            0.951, 1.028, 1.108, 1.191, 1.277, 1.366, 1.458, 1.553,
            1.651, 1.752, 1.856, 1.963, 2.073, 2.186, 2.302, 2.421,
            2.543, 2.668, 2.796, 2.927, 3.061, 3.198, 3.338, 3.481,
            3.627, 3.776, 3.928, 4.083, 4.241, 4.402, 4.566, 4.733,
            4.903, 5.076, 5.252, 5.431, 5.613, 5.798, 5.986, 6.177,
            6.371, 6.568, 6.768, 6.971, 7.177, 7.386, 7.598, 7.813,
            8.031, 8.252, 8.476, 8.703, 8.933, 9.166, 9.402, 9.641,
            9.883, 10.128, 10.376, 10.627, 10.881, 11.138, 11.398, 11.661,
            11.927, 12.196, 12.468, 12.743, 13.021, 13.302, 13.586, 13.873,
            14.163, 14.456, 14.752, 15.051, 15.353, 15.658, 15.966, 16.277,
            16.591, 16.908, 17.228, 17.551, 17.877, 18.206, 18.538, 18.873,
            19.211, 19.552, 19.896, 20.243, 20.593, 20.946, 21.302, 21.661,
            22.023, 22.388, 22.756, 23.127, 23.501, 23.878, 24.258, 24.641,
            25.027, 25.416, 25.808, 26.203, 26.601, 27.002, 27.406, 27.813
        ])
        
        if revision_type == 'early':
            dac_early = dac_standard.copy()
            dac_early = dac_early * 0.98
            dac_early[-20:] = dac_early[-20:] * 1.02
            return dac_early / dac_early[-1]
        
        elif revision_type == 'famicom':
            dac_famicom = dac_standard.copy()
            dac_famicom = np.power(dac_famicom / dac_famicom[-1], 0.95) * dac_famicom[-1]
            return dac_famicom / dac_famicom[-1]
        
        else:
            return dac_standard / dac_standard[-1]
    
    dac_lut = get_dac_lut(revision)
    
    # Чтение файла
    rate, data = wav.read(input_path)
    
    if len(data.shape) > 1:
        data = data.mean(axis=1).astype(np.float64)
    else:
        data = data.astype(np.float64)
    
    if qs['anti_aliasing']:
        b_pre, a_pre = signal.butter(4, qs['pre_filter_cutoff'] / (rate / 2), btype='low')
        data = signal.filtfilt(b_pre, a_pre, data)
    
    input_peak = np.max(np.abs(data))
    if input_peak > 0:
        data = data / input_peak * 0.5
    
    duration = len(data) / rate
    nes_len = int(duration * NES_RATE)
    
    if quality == 'high':
        resampled = signal.resample(data, nes_len)
    else:
        resampled = np.interp(
            np.linspace(0, duration, nes_len),
            np.linspace(0, duration, len(data)),
            data
        )
    
    # DPCM кодирование
    dpcm_bits = []
    current_val = 0.0
    base_step = 1.0 / 64.0
    
    for sample in resampled:
        sample = np.clip(sample, -0.95, 0.95)
        sample_normalized = (sample + 1.0) / 2.0
        
        if sample_normalized >= current_val:
            dpcm_bits.append(1)
            current_val += base_step
        else:
            dpcm_bits.append(0)
            current_val -= base_step
        
        current_val = np.clip(current_val, 0.0, 1.0)
    
    # Декодирование
    decoded = np.zeros(len(dpcm_bits), dtype=np.float64)
    current_val = 0.0
    
    for i, bit in enumerate(dpcm_bits):
        if bit == 1:
            current_val += base_step
        else:
            current_val -= base_step
        
        current_val = np.clip(current_val, 0.0, 1.0)
        dac_index = min(127, max(0, int(current_val * 127)))
        decoded[i] = dac_lut[dac_index]
    
    decoded = (decoded - 0.5) * 2.0
    
    # Сглаживание
    if quality != 'low' and not disable_dpcm_smoothing:
        decoded = gaussian_filter1d(decoded, sigma=qs['smoothing_sigma'], mode='nearest')
    
    b_smooth, a_smooth = signal.butter(3, qs['post_filter_cutoff'] / (NES_RATE / 2), btype='low')
    decoded = signal.filtfilt(b_smooth, a_smooth, decoded)
    
    if qs['noise_reduction'] > 0:
        smoothed = gaussian_filter1d(decoded, sigma=0.5)
        decoded = decoded * (1 - qs['noise_reduction']) + smoothed * qs['noise_reduction']
    
    b, a = signal.butter(2, 14000 / (NES_RATE / 2), btype='low')
    decoded = signal.lfilter(b, a, decoded)
    
    # Нормализация
    if export_mode == 'safe':
        peak_val = np.max(np.abs(decoded))
        if peak_val > 0.95:
            decoded = decoded * (0.95 / peak_val)
    elif export_mode == 'authentic':
        peak_val = np.max(np.abs(decoded))
        if peak_val > 1.0:
            decoded = decoded * (0.98 / peak_val)
        decoded = np.tanh(decoded * 1.1)
    elif export_mode == 'soft':
        threshold = 0.7
        ratio = 3.0
        mask = np.abs(decoded) > threshold
        excess = np.abs(decoded[mask]) - threshold
        decoded[mask] = np.sign(decoded[mask]) * (threshold + excess / ratio)
        peak_val = np.max(np.abs(decoded))
        if peak_val > 0:
            decoded = decoded * (0.95 / peak_val)
    
    if export_mode != 'raw' and quality != 'low':
        decoded = np.tanh(decoded * 1.05)
    
    # Добавление шума
    if add_artifacts and export_mode != 'raw' and quality != 'low':
        noise_level = 0.0002 if quality == 'high' else 0.0005
        noise = np.random.normal(0, noise_level, len(decoded))
        b_noise, a_noise = signal.butter(2, 8000 / (NES_RATE / 2), btype='low')
        noise = signal.filtfilt(b_noise, a_noise, noise)
        decoded = decoded + noise
    
    # Ресемплинг на 44100
    output_len = int(duration * 44100)
    
    if quality == 'high':
        tck = interpolate.splrep(np.linspace(0, duration, len(decoded)), decoded, s=0)
        final_audio = interpolate.splev(np.linspace(0, duration, output_len), tck, der=0)
    else:
        final_audio = np.interp(
            np.linspace(0, duration, output_len),
            np.linspace(0, duration, len(decoded)),
            decoded
        )
    
    if quality == 'high':
        b_final, a_final = signal.butter(4, 16000 / 22050, btype='low')
        final_audio = signal.filtfilt(b_final, a_final, final_audio)
    
    final_peak = np.max(np.abs(final_audio))
    if final_peak > 0.99:
        final_audio = final_audio * (0.99 / final_peak)
    
    final_audio_int16 = np.clip(final_audio * 32767, -32768, 32767).astype(np.int16)
    wav.write(output_path, 44100, final_audio_int16)
    
    print(f"✅ NES-стиль WAV сохранен: {output_path}")
    print(f"📊 Ревизия: {revision} | Режим: {export_mode} | Качество: {quality}")
    print(f"🎵 Сглаживание DPCM: {'Отключено' if disable_dpcm_smoothing else 'Включено'}")
    
    return output_path


def wav_to_nes_clean(input_path, output_path):
    """Экспорт с максимальным подавлением хруста"""
    return wav_to_nes_style_enhanced(
        input_path, 
        output_path,
        revision='standard',
        add_artifacts=False,
        export_mode='safe',
        quality='high'
    )


# === ТОЧКА ВХОДА ДЛЯ КОМАНДНОЙ СТРОКИ ===
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Использование:")
        print("  python dpcm.py ultraclean <input.wav> <output.wav> [preserve_timbre=true/false]")
        print("  python dpcm.py enhanced <input.wav> <output.wav> [revision] [quality] [export_mode] [add_artifacts] [disable_smoothing]")
        print("  python dpcm.py clean <input.wav> <output.wav>")
        sys.exit(1)
    
    command = sys.argv[1].lower()
    
    if command == "ultraclean":
        if len(sys.argv) < 4:
            print("Ошибка: укажите входной и выходной файлы")
            sys.exit(1)
        
        input_file = sys.argv[2]
        output_file = sys.argv[3]
        preserve_timbre = True
        
        if len(sys.argv) > 4:
            preserve_timbre = sys.argv[4].lower() in ['true', '1', 'yes']
        
        wav_to_nes_ultraclean(input_file, output_file, preserve_timbre)
    
    elif command == "enhanced":
        if len(sys.argv) < 4:
            print("Ошибка: укажите входной и выходной файлы")
            sys.exit(1)
        
        input_file = sys.argv[2]
        output_file = sys.argv[3]
        
        revision = sys.argv[4] if len(sys.argv) > 4 else 'standard'
        quality = sys.argv[5] if len(sys.argv) > 5 else 'high'
        export_mode = sys.argv[6] if len(sys.argv) > 6 else 'safe'
        add_artifacts = sys.argv[7].lower() in ['true', '1', 'yes'] if len(sys.argv) > 7 else True
        disable_smoothing = sys.argv[8].lower() in ['true', '1', 'yes'] if len(sys.argv) > 8 else False
        
        wav_to_nes_style_enhanced(
            input_file, output_file,
            revision=revision,
            quality=quality,
            export_mode=export_mode,
            add_artifacts=add_artifacts,
            disable_dpcm_smoothing=disable_smoothing
        )
    
    elif command == "clean":
        if len(sys.argv) < 4:
            print("Ошибка: укажите входной и выходной файлы")
            sys.exit(1)
        
        input_file = sys.argv[2]
        output_file = sys.argv[3]
        
        wav_to_nes_clean(input_file, output_file)
    
    else:
        print(f"Неизвестная команда: {command}")
        sys.exit(1)