from PIL import Image
import argparse

def reduce_to_4_colors(input_path, output_path):
    # Открываем изображение и конвертируем в RGB (на случай если там RGBA)
    img = Image.open(input_path).convert("RGB")
    
    # Главный секрет: Convert в режим "P" (палитровый) с 4 цветами
    # PIL сам проведёт квантование и выберет лучшие цвета
    img_reduced = img.convert("P", palette=Image.Palette.ADAPTIVE, colors=4)
    
    # Сохраняем. При сохранении в PNG палитра будет вшита внутрь файла
    img_reduced.save(output_path, optimize=True)
    
    # Для информации: выведем HEX-коды получившейся палитры
    palette = img_reduced.getpalette()
    if palette:
        colors = [tuple(palette[i:i+3]) for i in range(0, 12, 3)] # Берем только первые 4 цвета
        print(f"Сгенерированная палитра (R,G,B):")
        for i, c in enumerate(colors):
            hex_code = '#{:02x}{:02x}{:02x}'.format(c[0], c[1], c[2])
            print(f"  Цвет {i+1}: {c} -> {hex_code}")
    
    print(f"Готово! Результат сохранён в: {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Уменьшаем пиксель-арт до 4 цветов')
    parser.add_argument('input', help='Путь к исходному файлу')
    parser.add_argument('output', help='Путь для сохранения результата')
    
    args = parser.parse_args()
    
    reduce_to_4_colors(args.input, args.output)