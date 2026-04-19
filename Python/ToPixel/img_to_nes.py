import cv2
import numpy as np
from PIL import Image
import argparse
import os
import json

# Точная палитра NES (54 цвета)
NES_PALETTE_RGB = [
    (0x66, 0x66, 0x66), (0x00, 0x2A, 0x66), (0x00, 0x66, 0x66), (0x00, 0x66, 0x2A),
    (0x2A, 0x66, 0x00), (0x66, 0x66, 0x00), (0x66, 0x2A, 0x00), (0x66, 0x00, 0x2A),
    (0x66, 0x00, 0x66), (0x2A, 0x00, 0x66), (0x00, 0x00, 0x66), (0x00, 0x00, 0x2A),
    (0x00, 0x00, 0x00), (0x66, 0x66, 0x66), (0x00, 0x4A, 0x8A), (0x00, 0x8A, 0x8A),
    (0x00, 0x8A, 0x4A), (0x4A, 0x8A, 0x00), (0x8A, 0x8A, 0x00), (0x8A, 0x4A, 0x00),
    (0x8A, 0x00, 0x4A), (0x8A, 0x00, 0x8A), (0x4A, 0x00, 0x8A), (0x00, 0x00, 0x8A),
    (0x00, 0x00, 0x4A), (0x00, 0x00, 0x00), (0x8A, 0x8A, 0x8A), (0x2A, 0x6A, 0xAA),
    (0x2A, 0xAA, 0xAA), (0x2A, 0xAA, 0x6A), (0x6A, 0xAA, 0x2A), (0xAA, 0xAA, 0x2A),
    (0xAA, 0x6A, 0x2A), (0xAA, 0x2A, 0x6A), (0xAA, 0x2A, 0xAA), (0x6A, 0x2A, 0xAA),
    (0x2A, 0x2A, 0xAA), (0x2A, 0x2A, 0x6A), (0x2A, 0x2A, 0x2A), (0xAA, 0xAA, 0xAA),
    (0x4A, 0x8A, 0xCC), (0x4A, 0xCC, 0xCC), (0x4A, 0xCC, 0x8A), (0x8A, 0xCC, 0x4A),
    (0xCC, 0xCC, 0x4A), (0xCC, 0x8A, 0x4A), (0xCC, 0x4A, 0x8A), (0xCC, 0x4A, 0xCC),
    (0x8A, 0x4A, 0xCC), (0x4A, 0x4A, 0xCC), (0x4A, 0x4A, 0x8A), (0x4A, 0x4A, 0x4A),
    (0xCC, 0xCC, 0xCC), (0x6A, 0xAA, 0xEE), (0x6A, 0xEE, 0xEE), (0x6A, 0xEE, 0xAA),
    (0xAA, 0xEE, 0x6A), (0xEE, 0xEE, 0x6A), (0xEE, 0xAA, 0x6A), (0xEE, 0x6A, 0xAA),
    (0xEE, 0x6A, 0xEE), (0xAA, 0x6A, 0xEE), (0x6A, 0x6A, 0xEE), (0x6A, 0x6A, 0xAA),
    (0x6A, 0x6A, 0x6A), (0xEE, 0xEE, 0xEE)
]

# Встроенные пресеты
PRESETS = {
    "default": {
        "pixel_size": 8,
        "k_colors": 0,
        "edge_threshold": 11,
        "saturation_boost": 1.2,
        "contrast_boost": 1.1,
        "use_nes_palette": False,
        "use_edge_enhance": True,
        "smoothing_strength": 1,
        "method": "smart"
    },
    "nes_retro": {
        "pixel_size": 8,
        "k_colors": 0,
        "edge_threshold": 9,
        "saturation_boost": 1.3,
        "contrast_boost": 1.2,
        "use_nes_palette": True,
        "use_edge_enhance": True,
        "smoothing_strength": 1,
        "method": "smart"
    },
    "chunky_pixels": {
        "pixel_size": 16,
        "k_colors": 16,
        "edge_threshold": 15,
        "saturation_boost": 1.4,
        "contrast_boost": 1.3,
        "use_nes_palette": False,
        "use_edge_enhance": True,
        "smoothing_strength": 2,
        "method": "simple"
    },
    "detailed": {
        "pixel_size": 4,
        "k_colors": 0,
        "edge_threshold": 7,
        "saturation_boost": 1.1,
        "contrast_boost": 1.0,
        "use_nes_palette": False,
        "use_edge_enhance": True,
        "smoothing_strength": 0,
        "method": "smart"
    },
    "gameboy": {
        "pixel_size": 8,
        "k_colors": 4,
        "edge_threshold": 10,
        "saturation_boost": 1.0,
        "contrast_boost": 1.2,
        "use_nes_palette": False,
        "use_edge_enhance": True,
        "smoothing_strength": 1,
        "method": "smart",
        "custom_palette": [(0x0F, 0x38, 0x0F), (0x30, 0x62, 0x30), (0x8B, 0xAC, 0x0F), (0x9B, 0xBC, 0x0F)]
    },
    "cga": {
        "pixel_size": 8,
        "k_colors": 4,
        "edge_threshold": 10,
        "saturation_boost": 1.0,
        "contrast_boost": 1.3,
        "use_nes_palette": False,
        "use_edge_enhance": True,
        "smoothing_strength": 1,
        "method": "smart",
        "custom_palette": [(0x00, 0x00, 0x00), (0x00, 0xAA, 0xAA), (0xAA, 0x00, 0xAA), (0xAA, 0xAA, 0xAA)]
    },
    "poster_art": {
        "pixel_size": 12,
        "k_colors": 8,
        "edge_threshold": 20,
        "saturation_boost": 1.5,
        "contrast_boost": 1.4,
        "use_nes_palette": False,
        "use_edge_enhance": False,
        "smoothing_strength": 3,
        "method": "smart"
    },
    "oil_painting": {
        "pixel_size": 6,
        "k_colors": 24,
        "edge_threshold": 25,
        "saturation_boost": 1.2,
        "contrast_boost": 1.1,
        "use_nes_palette": False,
        "use_edge_enhance": False,
        "smoothing_strength": 2,
        "method": "edge_preserving"
    }
}

def load_config(config_path):
    """Загружает конфигурацию из JSON файла"""
    with open(config_path, 'r', encoding='utf-8') as f:
        config = json.load(f)
    
    # Поддерживаем ссылки на пресеты
    if 'preset' in config:
        preset_name = config.pop('preset')
        if preset_name in PRESETS:
            preset_config = PRESETS[preset_name].copy()
            preset_config.update(config)
            config = preset_config
        else:
            print(f"⚠️ Пресет '{preset_name}' не найден, использую default")
            config = PRESETS['default'].copy()
            config.update(config)
    
    return config

def save_config(config, output_path):
    """Сохраняет конфигурацию в JSON файл"""
    # Создаём копию для сохранения (убираем custom_palette если он слишком большой)
    save_config = config.copy()
    if 'custom_palette' in save_config and len(save_config['custom_palette']) > 20:
        save_config['custom_palette'] = f"palette_with_{len(save_config['custom_palette'])}_colors"
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(save_config, f, indent=2, ensure_ascii=False)
    print(f"💾 Конфигурация сохранена: {output_path}")

def quantize_to_palette(image, palette):
    """Квантует изображение до заданной палитры"""
    pixels = np.array(image).reshape(-1, 3)
    palette = np.array(palette, dtype=np.uint8)
    
    distances = np.sqrt(((pixels[:, np.newaxis, :] - palette) ** 2).sum(axis=2))
    closest = palette[distances.argmin(axis=1)]
    
    return Image.fromarray(closest.reshape(image.size[1], image.size[0], 3).astype(np.uint8))

def smart_pixelart_with_ai(input_path, output_path, config):
    """
    Преобразование в пиксель-арт с настройками из конфига
    """
    # Загружаем
    img = cv2.imread(input_path)
    if img is None:
        raise ValueError(f"Не удалось загрузить изображение: {input_path}")
    
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    h, w = img.shape[:2]
    
    print(f"\n📸 Обработка: {os.path.basename(input_path)}")
    print(f"   Размер: {w}x{h}")
    
    # Выводим параметры конфига
    print(f"   Метод: {config.get('method', 'smart')}")
    print(f"   Размер пикселя: {config.get('pixel_size', 8)}px")
    if config.get('use_nes_palette', False):
        print(f"   🎮 NES палитра: включена")
    if config.get('custom_palette'):
        print(f"   🎨 Пользовательская палитра: {len(config['custom_palette'])} цветов")
    
    # Применяем выбранный метод
    method = config.get('method', 'smart')
    
    if method == 'smart':
        # 1. Сглаживание
        for _ in range(config.get('smoothing_strength', 1)):
            img_rgb = cv2.medianBlur(img_rgb, 3)
        
        # 2. Адаптивная пороговая сегментация
        gray = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2GRAY)
        edge_param = config.get('edge_threshold', 11)
        edges_adaptive = cv2.adaptiveThreshold(
            gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY, max(3, edge_param if edge_param % 2 else edge_param + 1), 2
        )
        
        # 3. K-means упрощение цветов
        pixels = img_rgb.reshape(-1, 3).astype(np.float32)
        
        k = config.get('k_colors', 0)
        if k == 0:
            k = min(24, max(4, len(pixels) // 3000))
        
        criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 20, 1.0)
        _, labels, centers = cv2.kmeans(
            pixels, k, None, criteria, 10, cv2.KMEANS_RANDOM_CENTERS
        )
        
        simplified = centers[labels.flatten()].reshape(h, w, 3).astype(np.uint8)
        
        # 4. Увеличение насыщенности и контраста
        if config.get('saturation_boost', 1.0) != 1.0 or config.get('contrast_boost', 1.0) != 1.0:
            hsv = cv2.cvtColor(simplified, cv2.COLOR_RGB2HSV).astype(np.float32)
            hsv[:, :, 1] = np.clip(hsv[:, :, 1] * config.get('saturation_boost', 1.2), 0, 255)
            hsv[:, :, 2] = np.clip(hsv[:, :, 2] * config.get('contrast_boost', 1.1), 0, 255)
            simplified = cv2.cvtColor(hsv.astype(np.uint8), cv2.COLOR_HSV2RGB)
        
        # 5. Накладываем края
        edges_3ch = cv2.cvtColor(edges_adaptive, cv2.COLOR_GRAY2RGB)
        
        if config.get('use_edge_enhance', True):
            final = cv2.bitwise_and(simplified, edges_3ch)
        else:
            final = simplified
        
        print(f"   🎨 Цветов после K-means: {k}")
        
    elif method == 'edge_preserving':
        smoothed = cv2.edgePreservingFilter(
            cv2.cvtColor(img_rgb, cv2.COLOR_RGB2BGR),
            flags=1,
            sigma_s=config.get('sigma_s', 60),
            sigma_r=config.get('sigma_r', 0.4)
        )
        final = cv2.cvtColor(smoothed, cv2.COLOR_BGR2RGB)
        
    elif method == 'simple':
        pil_img = Image.open(input_path).convert('RGB')
        k = config.get('k_colors', 32)
        quantized = pil_img.quantize(colors=k, method=Image.MEDIANCUT)
        final = np.array(quantized.convert('RGB'))
        print(f"   🎨 Цветов после квантования: {k}")
    
    else:
        raise ValueError(f"Неизвестный метод: {method}")
    
    # 6. Применяем палитру если нужно
    pil_img = Image.fromarray(final)
    
    if config.get('use_nes_palette', False):
        print("   🎮 Применяем NES палитру...")
        final = np.array(quantize_to_palette(pil_img, NES_PALETTE_RGB))
    elif config.get('custom_palette'):
        print(f"   🎨 Применяем пользовательскую палитру...")
        final = np.array(quantize_to_palette(pil_img, config['custom_palette']))
    
    # 7. Финальная пикселизация
    pixel_size = config.get('pixel_size', 8)
    small = cv2.resize(final, (w // pixel_size, h // pixel_size), interpolation=cv2.INTER_NEAREST)
    pixelated = cv2.resize(small, (w, h), interpolation=cv2.INTER_NEAREST)
    
    # 8. Сохраняем
    result = Image.fromarray(pixelated)
    result.save(output_path)
    
    # Статистика
    unique_colors = len(np.unique(pixelated.reshape(-1, 3), axis=0))
    print(f"   ✨ Итоговое количество цветов: {unique_colors}")
    print(f"   💾 Сохранено: {output_path}")
    
    return result

def batch_process(input_folder, output_folder, config):
    """Обрабатывает все изображения в папке"""
    os.makedirs(output_folder, exist_ok=True)
    
    supported_formats = ('.jpg', '.jpeg', '.png', '.bmp', '.tiff')
    files = [f for f in os.listdir(input_folder) if f.lower().endswith(supported_formats)]
    
    print(f"\n📁 Найдено файлов: {len(files)}")
    
    for i, filename in enumerate(files, 1):
        input_path = os.path.join(input_folder, filename)
        name, ext = os.path.splitext(filename)
        output_path = os.path.join(output_folder, f"{name}_pixelart.png")
        
        print(f"\n[{i}/{len(files)}] Обработка: {filename}")
        try:
            smart_pixelart_with_ai(input_path, output_path, config)
        except Exception as e:
            print(f"   ❌ Ошибка: {e}")

def list_presets():
    """Выводит список доступных пресетов"""
    print("\n📋 Доступные пресеты:")
    print("-" * 50)
    for name, preset in PRESETS.items():
        print(f"\n🔹 {name}:")
        print(f"   pixel_size: {preset.get('pixel_size', 8)}")
        print(f"   method: {preset.get('method', 'smart')}")
        print(f"   NES palette: {preset.get('use_nes_palette', False)}")
        if preset.get('custom_palette'):
            print(f"   custom palette: {len(preset['custom_palette'])} colors")
        print(f"   k_colors: {preset.get('k_colors', 'auto')}")

def create_config_template(output_path):
    """Создаёт шаблон конфигурационного файла"""
    template = {
        "preset": "default",  # можно указать любой пресет как основу
        "pixel_size": 8,
        "k_colors": 0,  # 0 = авто
        "edge_threshold": 11,
        "saturation_boost": 1.2,
        "contrast_boost": 1.1,
        "use_nes_palette": False,
        "use_edge_enhance": True,
        "smoothing_strength": 1,
        "method": "smart",
        # "custom_palette": [[255,0,0], [0,255,0], [0,0,255]]  # пример своей палитры
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(template, f, indent=2, ensure_ascii=False)
    
    print(f"📄 Шаблон конфигурации создан: {output_path}")

def main():
    parser = argparse.ArgumentParser(description='Преобразование фото в пиксель-арт с файлом конфигурации')
    parser.add_argument('input', help='Путь к входному файлу или папке')
    parser.add_argument('-o', '--output', default='output.png', help='Путь для сохранения')
    parser.add_argument('-c', '--config', help='Путь к JSON файлу конфигурации')
    parser.add_argument('-p', '--preset', choices=PRESETS.keys(), help='Использовать встроенный пресет')
    parser.add_argument('--create-config', metavar='OUTPUT', help='Создать шаблон конфигурации')
    parser.add_argument('--list-presets', action='store_true', help='Показать все пресеты')
    parser.add_argument('--batch', action='store_true', help='Пакетная обработка папки')
    parser.add_argument('--save-config', metavar='OUTPUT', help='Сохранить текущую конфигурацию в файл')
    
    args = parser.parse_args()
    
    # Показать пресеты
    if args.list_presets:
        list_presets()
        return
    
    # Создать шаблон конфигурации
    if args.create_config:
        create_config_template(args.create_config)
        return
    
    # Загружаем конфигурацию
    if args.config:
        config = load_config(args.config)
        print(f"✅ Загружена конфигурация: {args.config}")
    elif args.preset:
        config = PRESETS[args.preset].copy()
        print(f"✅ Используется пресет: {args.preset}")
    else:
        config = PRESETS["default"].copy()
        print("✅ Используется конфигурация по умолчанию")
    
    # Сохранить конфигурацию если нужно
    if args.save_config:
        save_config(config, args.save_config)
    
    # Обработка
    if args.batch:
        batch_process(args.input, args.output, config)
    else:
        smart_pixelart_with_ai(args.input, args.output, config)

if __name__ == "__main__":
    # Пакетная обработка папки с изображениями
    input_folder = "images"  # папка с исходными изображениями
    output_folder = "output"  # папка для результатов
    config = load_config("my_config.json")
    
    # Запустить пакетную обработку
    batch_process(input_folder, output_folder, config)