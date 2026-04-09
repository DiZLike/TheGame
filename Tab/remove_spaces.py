#!/usr/bin/env python3
"""
Скрипт для замены пробелов на табуляции в Python файлах.
По умолчанию заменяет 4 пробела на 1 табуляцию.
"""

import sys
import os

def spaces_to_tabs(file_path, spaces_per_tab=4):
    """Заменяет пробелы на табуляции в указанном файле"""
    
    # Проверяем существование файла
    if not os.path.exists(file_path):
        print(f"Ошибка: Файл '{file_path}' не найден")
        return False
    
    # Читаем содержимое файла
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
    
    # Заменяем пробелы на табуляции
    # Заменяем только пробелы в начале строк (отступы)
    lines = content.splitlines(keepends=True)
    modified_lines = []
    
    for line in lines:
        # Подсчитываем количество пробелов в начале строки
        stripped = line.lstrip(' ')
        leading_spaces = len(line) - len(stripped)
        
        if leading_spaces > 0:
            # Вычисляем количество табуляций
            tabs_count = leading_spaces // spaces_per_tab
            remaining_spaces = leading_spaces % spaces_per_tab
            # Создаем новую строку с табуляциями
            new_line = '\t' * tabs_count + ' ' * remaining_spaces + stripped
            modified_lines.append(new_line)
        else:
            modified_lines.append(line)
    
    # Сохраняем изменения
    with open(file_path, 'w', encoding='utf-8') as file:
        file.writelines(modified_lines)
    
    print(f"✓ Файл '{file_path}' обработан успешно")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Использование: python script.py <файл.py> [количество_пробелов]")
        print("Пример: python script.py myfile.py 4")
        sys.exit(1)
    
    file_path = sys.argv[1]
    spaces_count = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    
    spaces_to_tabs(file_path, spaces_count)