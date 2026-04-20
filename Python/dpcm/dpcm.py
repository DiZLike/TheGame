import numpy as np
import scipy.io.wavfile as wav
from scipy import signal
from scipy.ndimage import gaussian_filter1d
from scipy import interpolate

def wav_to_nes_ultraclean(input_path, output_path, preserve_timbre=True):
    """
    Преобразует WAV в звук NES с МИНИМАЛЬНЫМИ артефактами.
    Оптимизированная версия без хруста, треска и шума.
    
    Параметры:
    - input_path: путь к входному WAV
    - output_path: путь для сохранения
    - preserve_timbre: сохранять характерную окраску NES (True) или делать максимально чистый звук (False)
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
    # Используем polyphase фильтр для максимального качества
    resampled = signal.resample(data, nes_len)
    
    # Легкая фильтрация перед DPCM для удаления высоких частот
    b_pre, a_pre = signal.butter(4, 8000 / (NES_RATE/2), btype='low')
    resampled = signal.filtfilt(b_pre, a_pre, resampled)
    
    # Приводим к диапазону 0..1 для DPCM
    resampled = (resampled - resampled.min()) / (resampled.max() - resampled.min())
    resampled = np.clip(resampled, 0.05, 0.95)  # Избегаем крайних значений
    
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
    x_smooth = np.linspace(0, 1, 1024)  # Увеличенное разрешение
    dac_smooth = np.interp(x_smooth, x_orig, dac_lut)
    
    # === DPCM КОДИРОВАНИЕ С УЛУЧШЕННОЙ ТОЧНОСТЬЮ ===
    dpcm_bits = np.zeros(nes_len, dtype=np.uint8)
    current_val = 0.5  # Начинаем с середины
    base_step = 1.0 / 64.0
    
    # Оптимизированное DPCM кодирование
    for i in range(nes_len):
        sample = resampled[i]
        
        if sample >= current_val:
            dpcm_bits[i] = 1
            current_val += base_step
        else:
            dpcm_bits[i] = 0
            current_val -= base_step
        
        # Мягкое ограничение вместо жесткого клиппинга
        if current_val > 1.0:
            current_val = 1.0 - (current_val - 1.0) * 0.1
        elif current_val < 0.0:
            current_val = abs(current_val) * 0.1
        
        current_val = np.clip(current_val, 0.0, 1.0)
    
    # === ДЕКОДИРОВАНИЕ С ИСПОЛЬЗОВАНИЕМ СГЛАЖЕННОЙ ТАБЛИЦЫ ===
    decoded = np.zeros(nes_len, dtype=np.float64)
    current_val = 0.5
    step = 1.0 / 64.0
    
    for i in range(nes_len):
        if dpcm_bits[i] == 1:
            current_val += step
        else:
            current_val -= step
        
        current_val = np.clip(current_val, 0.0, 1.0)
        
        # Используем сглаженную таблицу DAC
        dac_index = int(current_val * 1023)
        decoded[i] = dac_smooth[dac_index]
    
    # === МНОГОСТУПЕНЧАТАЯ ФИЛЬТРАЦИЯ ДЛЯ УДАЛЕНИЯ АРТЕФАКТОВ ===
    
    # 1. Удаление DC смещения
    decoded = decoded - np.mean(decoded)
    
    # 2. Сглаживание резких переходов DPCM
    decoded = gaussian_filter1d(decoded, sigma=0.6, mode='nearest')
    
    # 3. Основной фильтр низких частот (убирает "хруст" и алиасинг)
    b1, a1 = signal.butter(6, 12000 / (NES_RATE/2), btype='low')
    decoded = signal.filtfilt(b1, a1, decoded)
    
    # 4. Дополнительный фильтр для подавления частоты дискретизации DPCM
    b2, a2 = signal.butter(4, 14000 / (NES_RATE/2), btype='low')
    decoded = signal.filtfilt(b2, a2, decoded)
    
    # 5. Нотч-фильтр на частоте Найквиста DPCM (убирает характерный свист)
    notch_freq = NES_RATE / 4
    b_notch, a_notch = signal.iirnotch(notch_freq, 20, NES_RATE)
    decoded = signal.filtfilt(b_notch, a_notch, decoded)
    
    # 6. Мягкое подавление шума квантования
    if preserve_timbre:
        # Легкая компрессия для сохранения характера NES
        decoded = np.tanh(decoded * 1.1)
    else:
        # Агрессивное шумоподавление для чистого звука
        decoded = gaussian_filter1d(decoded, sigma=0.3, mode='nearest')
    
    # === РЕСЕМПЛИНГ НА 44100 ГЦ ===
    output_len = int(duration * OUTPUT_RATE)
    
    # Используем высококачественную интерполяцию
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
    
    # Финальная фильтрация для удаления артефактов интерполяции
    b_final, a_final = signal.butter(8, 15000 / (OUTPUT_RATE/2), btype='low')
    final_audio = signal.filtfilt(b_final, a_final, final_audio)
    
    # === НОРМАЛИЗАЦИЯ И ЭКСПОРТ ===
    
    # Мягкая нормализация с запасом
    peak_out = np.max(np.abs(final_audio))
    if peak_out > 0:
        final_audio = final_audio / peak_out * 0.95
    
    # Плавное затухание в начале и конце (убирает щелчки)
    fade_len = min(512, len(final_audio) // 10)
    fade_in = np.linspace(0, 1, fade_len)
    fade_out = np.linspace(1, 0, fade_len)
    final_audio[:fade_len] *= fade_in
    final_audio[-fade_len:] *= fade_out
    
    # Конвертация в 16-бит
    final_audio_int16 = np.clip(final_audio * 32767, -32768, 32767).astype(np.int16)
    
    # Сохранение
    wav.write(output_path, OUTPUT_RATE, final_audio_int16)
    
    # Статистика
    print(f"✅ NES Ultraclean сохранен: {output_path}")
    print(f"📊 Параметры:")
    print(f"   - Длительность: {duration:.2f} сек")
    print(f"   - Частота NES: {NES_RATE} Гц")
    print(f"   - DPCM бит: {nes_len}")
    print(f"   - Пик сигнала: {peak_out:.3f}")
    print(f"   - Режим: {'NES-окраска' if preserve_timbre else 'Максимальная чистота'}")
    
    return output_path


def wav_to_nes_style_enhanced(input_path, output_path, revision='standard', 
                              add_artifacts=True, export_mode='safe',
                              quality='high', disable_dpcm_smoothing=False):
    """
    Преобразует WAV в звук, максимально похожий на DPCM-канал NES.
    Улучшенная версия с подавлением "хруста".
    
    Параметры:
    - input_path: путь к входному WAV файлу
    - output_path: путь для сохранения результата
    - revision: версия NES ('standard', 'early', 'famicom')
        * 'standard' - стандартная ревизия NES (NTSC)
        * 'early' - ранняя ревизия с немного другой кривой ЦАП
        * 'famicom' - японская Famicom с особенностями аналогового тракта
    - add_artifacts: добавлять ли характерные артефакты NES (шум квантования)
        * True - добавляет легкий шум для аутентичности
        * False - чистый звук без дополнительного шума
    - export_mode: режим экспорта ('safe', 'authentic', 'soft', 'raw')
        * 'safe' - безопасная нормализация с запасом по громкости
        * 'authentic' - эмуляция компрессии NES с насыщением (tanh)
        * 'soft' - мягкое ограничение пиков (софт-клиппинг)
        * 'raw' - минимальная обработка, только нормализация
    - quality: качество обработки ('high', 'medium', 'low')
        * 'high' - максимальное качество, сильная фильтрация артефактов
        * 'medium' - сбалансированное качество
        * 'low' - минимальная обработка, сохранение сырого звука
    - disable_dpcm_smoothing: отключить сглаживание переходов DPCM (Gaussian filter)
        * False - сглаживать ступеньки DPCM (более чистый звук)
        * True - оставить резкие переходы как на реальном NES (более аутентично)
    """
    
    # === ПАРАМЕТРЫ ЖЕЛЕЗА NES ===
    NES_RATE = 33144
    CPU_RATE = 1789773
    
    # === НАСТРОЙКИ КАЧЕСТВА ===
    quality_settings = {
        'high': {
            'pre_filter_cutoff': 8000,
            'post_filter_cutoff': 12000,
            'smoothing_sigma': 0.8,
            'noise_reduction': 0.7,
            'anti_aliasing': True
        },
        'medium': {
            'pre_filter_cutoff': 6000,
            'post_filter_cutoff': 10000,
            'smoothing_sigma': 0.5,
            'noise_reduction': 0.5,
            'anti_aliasing': True
        },
        'low': {
            'pre_filter_cutoff': 4000,
            'post_filter_cutoff': 8000,
            'smoothing_sigma': 0.3,
            'noise_reduction': 0.3,
            'anti_aliasing': False
        }
    }
    
    qs = quality_settings[quality]
    
    # === ТАБЛИЦЫ ЦАП ДЛЯ РАЗНЫХ РЕВИЗИЙ ===
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
    
    # === ОПТИМИЗИРОВАННЫЕ ФУНКЦИИ ОБРАБОТКИ ===
    def smooth_dpcm_transitions(signal_data, sigma=0.8):
        """Сглаживает резкие переходы DPCM"""
        return gaussian_filter1d(signal_data, sigma=sigma, mode='nearest')
    
    def reduce_quantization_noise(signal_data, strength=0.7):
        """Подавляет шум квантования"""
        smoothed = gaussian_filter1d(signal_data, sigma=0.5)
        return signal_data * (1 - strength) + smoothed * strength
    
    def apply_safe_normalization(audio, mode='safe'):
        """Применяет нормализацию в зависимости от режима"""
        if mode == 'safe':
            peak_val = np.max(np.abs(audio))
            if peak_val > 0.95:
                audio = audio * (0.95 / peak_val)
            
        elif mode == 'authentic':
            peak_val = np.max(np.abs(audio))
            if peak_val > 1.0:
                audio = audio * (0.98 / peak_val)
            audio = np.tanh(audio * 1.1)
            
        elif mode == 'soft':
            threshold = 0.7
            ratio = 3.0
            mask = np.abs(audio) > threshold
            excess = np.abs(audio[mask]) - threshold
            audio[mask] = np.sign(audio[mask]) * (threshold + excess / ratio)
            peak_val = np.max(np.abs(audio))
            if peak_val > 0:
                audio = audio * (0.95 / peak_val)
                
        elif mode == 'raw':
            peak_val = np.max(np.abs(audio))
            if peak_val > 1.0:
                audio = audio / peak_val
                
        return audio
    
    # === ЧТЕНИЕ И ПОДГОТОВКА ===
    rate, data = wav.read(input_path)
    
    # Моно
    if len(data.shape) > 1:
        data = data.mean(axis=1).astype(np.float64)
    else:
        data = data.astype(np.float64)
    
    # Предварительная фильтрация
    if qs['anti_aliasing']:
        b_pre, a_pre = signal.butter(4, qs['pre_filter_cutoff'] / (rate / 2), btype='low')
        data = signal.filtfilt(b_pre, a_pre, data)
    
    # Нормализация
    input_peak = np.max(np.abs(data))
    if input_peak > 0:
        data = data / input_peak * 0.5
    
    # Ресемплинг
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
    
    # === DPCM КОДИРОВАНИЕ ===
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
    
    # === ДЕКОДИРОВАНИЕ ===
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
    
    # === ПОДАВЛЕНИЕ АРТЕФАКТОВ ===
    if quality != 'low' and not disable_dpcm_smoothing:
        decoded = smooth_dpcm_transitions(decoded, sigma=qs['smoothing_sigma'])
    
    b_smooth, a_smooth = signal.butter(3, qs['post_filter_cutoff'] / (NES_RATE / 2), btype='low')
    decoded = signal.filtfilt(b_smooth, a_smooth, decoded)
    
    if qs['noise_reduction'] > 0:
        decoded = reduce_quantization_noise(decoded, strength=qs['noise_reduction'])
    
    # === ПОСТ-ОБРАБОТКА ===
    b, a = signal.butter(2, 14000 / (NES_RATE / 2), btype='low')
    decoded = signal.lfilter(b, a, decoded)
    
    decoded = apply_safe_normalization(decoded, export_mode)
    
    if export_mode != 'raw' and quality != 'low':
        decoded = np.tanh(decoded * 1.05)
    
    # Легкий шум (опционально)
    if add_artifacts and export_mode != 'raw' and quality != 'low':
        noise_level = 0.0002 if quality == 'high' else 0.0005
        noise = np.random.normal(0, noise_level, len(decoded))
        b_noise, a_noise = signal.butter(2, 8000 / (NES_RATE / 2), btype='low')
        noise = signal.filtfilt(b_noise, a_noise, noise)
        decoded = decoded + noise
    
    # === РЕСЕМПЛИНГ НА 44100 ГЦ ===
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
    
    # Финальная фильтрация
    if quality == 'high':
        b_final, a_final = signal.butter(4, 16000 / 22050, btype='low')
        final_audio = signal.filtfilt(b_final, a_final, final_audio)
    
    # Нормализация и экспорт
    final_peak = np.max(np.abs(final_audio))
    if final_peak > 0.99:
        final_audio = final_audio * (0.99 / final_peak)
    
    final_audio_int16 = np.clip(final_audio * 32767, -32768, 32767).astype(np.int16)
    wav.write(output_path, 44100, final_audio_int16)
    
    # Статистика
    print(f"✅ NES-стиль WAV сохранен: {output_path}")
    print(f"📊 Параметры:")
    print(f"   - Ревизия: {revision}")
    print(f"   - Режим: {export_mode}")
    print(f"   - Качество: {quality}")
    print(f"   - Сглаживание DPCM: {'Отключено (аутентично)' if disable_dpcm_smoothing else 'Включено (чистый звук)'}")
    print(f"   - Длительность: {duration:.2f} сек")
    print(f"   - Пик: {final_peak:.2f}")
    
    return output_path


def wav_to_nes_clean(input_path, output_path):
    """
    Экспорт с максимальным подавлением "хруста"
    """
    return wav_to_nes_style_enhanced(
        input_path, 
        output_path,
        revision='standard',
        add_artifacts=False,
        export_mode='safe',
        quality='high'
    )


# === ПРИМЕР ИСПОЛЬЗОВАНИЯ ===
if __name__ == "__main__":
    # Для максимальной аутентичности NES (с резкими переходами DPCM)
    wav_to_nes_style_enhanced("1.wav", "authentic_nes_hard.wav", 
                              revision='standard', 
                              add_artifacts=True, 
                              export_mode='authentic', 
                              quality='high',
                              disable_dpcm_smoothing=True)  # ← ОТКЛЮЧЕНО сглаживание для реального звука NES
    
    # Для максимальной аутентичности NES (со сглаженными переходами)
    wav_to_nes_style_enhanced("1.wav", "authentic_nes_soft.wav", 
                              revision='standard', 
                              add_artifacts=True, 
                              export_mode='authentic', 
                              quality='high',
                              disable_dpcm_smoothing=False)  # ← ВКЛЮЧЕНО сглаживание

    # Для максимальной чистоты
    wav_to_nes_ultraclean("1.wav", "cleanest.wav", preserve_timbre=False)

    # Компромиссный вариант
    wav_to_nes_style_enhanced("1.wav", "balanced.wav",
                              revision='standard', 
                              add_artifacts=False, 
                              export_mode='safe', 
                              quality='high')

    # Для lo-fi эффекта
    wav_to_nes_style_enhanced("1.wav", "lofi_nes.wav",
                              revision='early', 
                              add_artifacts=True, 
                              export_mode='raw', 
                              quality='low')
    
    print("\n✨ Все преобразования завершены!")