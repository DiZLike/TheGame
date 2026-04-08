using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Text.Json;

namespace SpritePacker
{
    class Program
    {
        private static Config _config;

        static void Main(string[] args)
        {
            Console.WriteLine("=== Sprite Packer (Auto Grid) ===");
            Console.WriteLine();

            // Загрузка конфигурации
            _config = LoadConfig();

            if (_config == null)
            {
                Console.WriteLine("Не удалось загрузить конфигурацию. Создан файл конфигурации по умолчанию.");
                Console.ReadKey();
                return;
            }

            // Вывод настроек
            PrintConfig();

            // Создаем папку для спрайтов, если её нет
            if (!Directory.Exists(_config.InputFolder))
            {
                Directory.CreateDirectory(_config.InputFolder);
                Console.WriteLine($"Создана папка '{_config.InputFolder}'. Поместите туда подпапки с анимациями и запустите программу снова.");
                Console.ReadKey();
                return;
            }

            // Сканируем подпапки в папке sprites
            var animationFolders = Directory.GetDirectories(_config.InputFolder)
                .Select(f => new DirectoryInfo(f))
                .Where(d => d.GetFiles().Any(f => f.Extension.ToLower() == ".png" ||
                                                   f.Extension.ToLower() == ".jpg" ||
                                                   f.Extension.ToLower() == ".jpeg" ||
                                                   f.Extension.ToLower() == ".bmp"))
                .ToList();

            if (animationFolders.Count == 0)
            {
                Console.WriteLine($"Не найдено подпапок с изображениями в папке '{_config.InputFolder}'.");
                Console.WriteLine("Создайте подпапки с названиями анимаций и поместите в них спрайты.");
                Console.ReadKey();
                return;
            }

            Console.WriteLine($"\nНайдено анимаций: {animationFolders.Count}");

            // Загружаем спрайты и группируем по анимациям
            var animations = new List<Animation>();
            int maxWidth = 0;
            int maxHeight = 0;
            int maxAnimationLength = 0;

            foreach (var folder in animationFolders)
            {
                var animation = new Animation
                {
                    Name = folder.Name,
                    Sprites = new List<Sprite>(),
                    OffsetX = 0,
                    OffsetY = 0
                };

                // Загружаем смещение для анимации
                LoadAnimationOffset(folder.FullName, animation);

                var imageFiles = folder.GetFiles()
                    .Where(f => f.Extension.ToLower() == ".png" ||
                               f.Extension.ToLower() == ".jpg" ||
                               f.Extension.ToLower() == ".jpeg" ||
                               f.Extension.ToLower() == ".bmp")
                    .OrderBy(f => f.Name)
                    .ToList();

                Console.WriteLine($"\nАнимация '{animation.Name}': {imageFiles.Count} кадров");
                if (animation.OffsetX != 0 || animation.OffsetY != 0)
                {
                    Console.WriteLine($"  Загружено смещение из offset.txt: X={animation.OffsetX}, Y={animation.OffsetY}");
                }

                if (imageFiles.Count > maxAnimationLength)
                {
                    maxAnimationLength = imageFiles.Count;
                }

                foreach (var file in imageFiles)
                {
                    try
                    {
                        var image = Image.FromFile(file.FullName);
                        var sprite = new Sprite
                        {
                            Name = Path.GetFileNameWithoutExtension(file.Name),
                            Image = image,
                            Width = image.Width,
                            Height = image.Height,
                            OriginalWidth = image.Width,
                            OriginalHeight = image.Height,
                            AnimationName = animation.Name
                        };
                        animation.Sprites.Add(sprite);

                        maxWidth = Math.Max(maxWidth, image.Width);
                        maxHeight = Math.Max(maxHeight, image.Height);

                        Console.WriteLine($"  - {file.Name}: {image.Width}x{image.Height}");
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Ошибка загрузки {file.Name}: {ex.Message}");
                    }
                }

                if (animation.Sprites.Count > 0)
                {
                    animations.Add(animation);
                }
            }

            if (animations.Count == 0 || animations.Sum(a => a.Sprites.Count) == 0)
            {
                Console.WriteLine("Не удалось загрузить ни одного спрайта.");
                Console.ReadKey();
                return;
            }

            // Определяем количество колонок
            int columns = _config.Columns;
            if (_config.AutoColumns || columns == 0)
            {
                columns = maxAnimationLength;
                Console.WriteLine($"\nАвтоматически определено количество колонок (по максимальной длине анимации): {columns}");
            }

            // Размер ячейки определяется максимальным размером спрайта
            int cellWidth = maxWidth;
            int cellHeight = maxHeight;

            if (_config.UseSquareCells)
            {
                int maxSize = Math.Max(maxWidth, maxHeight);
                cellWidth = maxSize;
                cellHeight = maxSize;
                Console.WriteLine($"\nИспользуются квадратные ячейки: {cellWidth}x{cellHeight}");
            }
            else
            {
                Console.WriteLine($"\nРазмер ячейки (по максимальному спрайту): {cellWidth}x{cellHeight}");
            }

            Console.WriteLine($"Колонок: {columns}");
            Console.WriteLine($"Отступ: {_config.Padding}px");
            Console.WriteLine($"Максимальная длина анимации: {maxAnimationLength} кадров");
            Console.WriteLine($"Вертикальное выравнивание: {(_config.VerticalAlignment == "bottom" ? "по нижнему краю" : "по центру")}");

            // Рассчитываем количество строк для каждой анимации
            int totalRows = 0;
            var animationLayout = new List<AnimationLayout>();

            foreach (var animation in animations)
            {
                int rowsForAnimation = (int)Math.Ceiling((double)animation.Sprites.Count / columns);
                animationLayout.Add(new AnimationLayout
                {
                    Animation = animation,
                    Rows = rowsForAnimation,
                    StartRow = totalRows
                });
                totalRows += rowsForAnimation;

                Console.WriteLine($"  Анимация '{animation.Name}': {animation.Sprites.Count} кадров -> {rowsForAnimation} строк(и)");
            }

            // Вычисляем размеры спрайт-листа
            int sheetWidth = columns * (cellWidth + _config.Padding) + _config.Padding;
            int sheetHeight = totalRows * (cellHeight + _config.Padding) + _config.Padding;

            Console.WriteLine($"\nСоздание спрайт-листа размером {sheetWidth}x{sheetHeight}...");
            Console.WriteLine($"Всего строк: {totalRows}, Колонок: {columns}");
            Console.WriteLine($"Всего кадров: {animations.Sum(a => a.Sprites.Count)}");

            var allSpritesWithPositions = new List<SpritePosition>();

            // Создаем итоговое изображение
            using (var spriteSheet = new Bitmap(sheetWidth, sheetHeight))
            using (var graphics = Graphics.FromImage(spriteSheet))
            {
                graphics.Clear(Color.Transparent);

                if (_config.PixelArtMode)
                {
                    graphics.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighSpeed;
                    graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.NearestNeighbor;
                    graphics.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.Half;
                    graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.None;
                }
                else
                {
                    graphics.CompositingQuality = System.Drawing.Drawing2D.CompositingQuality.HighQuality;
                    graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                    graphics.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
                    graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.HighQuality;
                }

                int globalSpriteIndex = 0;

                foreach (var layout in animationLayout)
                {
                    var animation = layout.Animation;
                    int currentRow = layout.StartRow;

                    for (int i = 0; i < animation.Sprites.Count; i++)
                    {
                        int col = i % columns;
                        int row = currentRow + (i / columns);

                        // Вычисляем позицию ячейки
                        int cellX = _config.Padding + col * (cellWidth + _config.Padding);
                        int cellY = _config.Padding + row * (cellHeight + _config.Padding);

                        var sprite = animation.Sprites[i];

                        // Сохраняем позицию ячейки (верхний левый угол ячейки)
                        sprite.X = cellX;
                        sprite.Y = cellY;
                        sprite.Placed = true;

                        // Рисуем спрайт в ячейке с выбранным выравниванием и смещением
                        var (drawX, drawY) = CalculateDrawPosition(
                            cellX, cellY, cellWidth, cellHeight,
                            sprite.Width, sprite.Height,
                            _config.PixelArtMode,
                            _config.VerticalAlignment,
                            animation.OffsetX,
                            animation.OffsetY);

                        // Рисуем спрайт в оригинальном размере (без масштабирования!)
                        graphics.DrawImage(sprite.Image, drawX, drawY, sprite.Width, sprite.Height);

                        allSpritesWithPositions.Add(new SpritePosition
                        {
                            Sprite = sprite,
                            AnimationName = animation.Name,
                            Row = row,
                            Column = col,
                            X = drawX,
                            Y = drawY,
                            DrawWidth = sprite.Width,
                            DrawHeight = sprite.Height,
                            GlobalIndex = globalSpriteIndex++,
                            OffsetX = animation.OffsetX,
                            OffsetY = animation.OffsetY
                        });
                    }
                }

                // Сохраняем результат
                string outputPath = Path.Combine(_config.OutputFolder, _config.OutputImage);

                // Создаем папку если не существует
                if (!Directory.Exists(_config.OutputFolder))
                {
                    Directory.CreateDirectory(_config.OutputFolder);
                }

                if (_config.PixelArtMode)
                {
                    var encoderParams = new EncoderParameters(1);
                    encoderParams.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, 100L);

                    var pngCodec = ImageCodecInfo.GetImageDecoders()
                        .FirstOrDefault(codec => codec.FormatID == ImageFormat.Png.Guid);

                    if (pngCodec != null)
                    {
                        spriteSheet.Save(outputPath, pngCodec, encoderParams);
                    }
                    else
                    {
                        spriteSheet.Save(outputPath, ImageFormat.Png);
                    }
                }
                else
                {
                    spriteSheet.Save(outputPath, ImageFormat.Png);
                }
            }

            // Освобождаем изображения после сохранения спрайт-листа
            foreach (var anim in animations)
            {
                foreach (var sprite in anim.Sprites)
                {
                    sprite.Image?.Dispose();
                }
            }

            // Создаем текстовый отчет
            CreateReport(animations, allSpritesWithPositions, cellWidth, cellHeight,
                        columns, totalRows, sheetWidth, sheetHeight, maxAnimationLength);

            string outputPathFinal = Path.Combine(_config.OutputFolder, _config.OutputImage);

            Console.WriteLine($"\n✅ Готово!");
            Console.WriteLine($"📁 Спрайт-лист сохранен: {outputPathFinal}");
            Console.WriteLine($"📄 Отчет сохранен: {Path.Combine(_config.OutputFolder, "packer_report.txt")}");
            Console.WriteLine($"📊 Всего анимаций: {animations.Count}");
            Console.WriteLine($"🎬 Всего кадров: {allSpritesWithPositions.Count}");
            Console.WriteLine($"📐 Размер ячейки: {cellWidth}x{cellHeight}");
            Console.WriteLine($"🎯 Колонок: {columns} (макс. длина анимации: {maxAnimationLength})");

            // Выводим информацию о размерах ячеек для каждой анимации (если размеры разные)
            var uniqueSizes = allSpritesWithPositions
                .Select(s => $"{s.DrawWidth}x{s.DrawHeight}")
                .Distinct()
                .ToList();

            if (uniqueSizes.Count > 1)
            {
                Console.WriteLine($"⚠️  Внимание: анимации используют спрайты разных размеров:");
                foreach (var size in uniqueSizes)
                {
                    int count = allSpritesWithPositions.Count(s => $"{s.DrawWidth}x{s.DrawHeight}" == size);
                    Console.WriteLine($"     - {size}: {count} спрайтов");
                }
                Console.WriteLine($"   Все спрайты сохранены в оригинальном размере.");
            }

            // Выводим информацию об анимациях
            Console.WriteLine("\n=== Анимации ===");
            foreach (var anim in animations)
            {
                int rowsUsed = (int)Math.Ceiling((double)anim.Sprites.Count / columns);
                var sizes = anim.Sprites.Select(s => $"{s.Width}x{s.Height}").Distinct().ToList();
                string sizeInfo = sizes.Count == 1 ? $"{sizes[0]}" : $"разные размеры ({string.Join(", ", sizes)})";
                string offsetInfo = (anim.OffsetX != 0 || anim.OffsetY != 0) ? $", смещение: ({anim.OffsetX}, {anim.OffsetY})" : "";
                Console.WriteLine($"  {anim.Name}: {anim.Sprites.Count} кадров, {rowsUsed} строк(и), размеры: {sizeInfo}{offsetInfo}");
            }

            Console.ReadKey();
        }

        private static void LoadAnimationOffset(string folderPath, Animation animation)
        {
            string offsetFile = Path.Combine(folderPath, "offset.txt");

            if (!File.Exists(offsetFile))
            {
                return; // Нет файла смещения, используем 0,0
            }

            try
            {
                string content = File.ReadAllText(offsetFile).Trim();

                // Пробуем распарсить два числа, разделенных пробелом, табуляцией или запятой
                string[] parts = content.Split(new[] { ' ', '\t', ',', ';' }, StringSplitOptions.RemoveEmptyEntries);

                if (parts.Length >= 2)
                {
                    if (int.TryParse(parts[0], out int offsetX) && int.TryParse(parts[1], out int offsetY))
                    {
                        animation.OffsetX = offsetX;
                        animation.OffsetY = offsetY;
                    }
                    else
                    {
                        Console.WriteLine($"  Предупреждение: не удалось распарсить offset.txt в {offsetFile}. Ожидались два целых числа.");
                    }
                }
                else
                {
                    Console.WriteLine($"  Предупреждение: файл offset.txt в {offsetFile} содержит недостаточно чисел. Ожидалось два числа.");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"  Ошибка загрузки offset.txt: {ex.Message}");
            }
        }

        private static (int drawX, int drawY) CalculateDrawPosition(
            int cellX, int cellY, int cellWidth, int cellHeight,
            int spriteWidth, int spriteHeight, bool pixelArtMode,
            string verticalAlignment, int offsetX, int offsetY)
        {
            // Горизонтальное выравнивание всегда по центру
            int drawX = cellX + (cellWidth - spriteWidth) / 2;

            // Вертикальное выравнивание
            int drawY;
            if (verticalAlignment == "bottom")
            {
                // Привязка к нижнему краю
                drawY = cellY + (cellHeight - spriteHeight);
            }
            else // "center" по умолчанию
            {
                // Центрирование
                drawY = cellY + (cellHeight - spriteHeight) / 2;
            }

            // Применяем смещение анимации
            drawX += offsetX;
            drawY += offsetY;

            // Для пиксель-арта округляем до целых
            if (pixelArtMode)
            {
                drawX = (int)Math.Round((decimal)drawX);
                drawY = (int)Math.Round((decimal)drawY);
            }

            return (drawX, drawY);
        }

        private static Config LoadConfig()
        {
            string configFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "packer_config.json");

            if (File.Exists(configFile))
            {
                try
                {
                    string json = File.ReadAllText(configFile);
                    var config = JsonSerializer.Deserialize<Config>(json);

                    if (config != null)
                    {
                        return config;
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Ошибка загрузки конфигурации: {ex.Message}");
                }
            }

            var defaultConfig = new Config();
            string defaultJson = JsonSerializer.Serialize(defaultConfig, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(configFile, defaultJson);

            return defaultConfig;
        }

        private static void PrintConfig()
        {
            Console.WriteLine("=== Текущие настройки ===");
            Console.WriteLine($"Входная папка: {_config.InputFolder}");
            Console.WriteLine($"Выходная папка: {_config.OutputFolder}");
            Console.WriteLine($"Выходной файл: {_config.OutputImage}");
            Console.WriteLine($"Колонок: {(_config.AutoColumns ? "авто (по макс. длине анимации)" : _config.Columns.ToString())}");
            Console.WriteLine($"Отступ: {_config.Padding}px");
            Console.WriteLine($"Режим пиксель-арта: {_config.PixelArtMode}");
            Console.WriteLine($"Квадратные ячейки: {_config.UseSquareCells}");
            Console.WriteLine($"Авто-колонки: {_config.AutoColumns}");
            Console.WriteLine($"Вертикальное выравнивание: {(_config.VerticalAlignment == "bottom" ? "по нижнему краю" : "по центру")}");
            Console.WriteLine($"⚠️  ВНИМАНИЕ: спрайты сохраняются в ОРИГИНАЛЬНОМ размере (без масштабирования)");
            Console.WriteLine("===========================");
        }

        private static void CreateReport(List<Animation> animations, List<SpritePosition> sprites,
                                        int cellWidth, int cellHeight, int columns,
                                        int totalRows, int sheetWidth, int sheetHeight, int maxAnimationLength)
        {
            string reportPath = Path.Combine(_config.OutputFolder, "packer_report.txt");

            using (var writer = new StreamWriter(reportPath))
            {
                writer.WriteLine("=== ОТЧЕТ ОБ УПАКОВКЕ СПРАЙТОВ ===");
                writer.WriteLine($"Дата: {DateTime.Now}");
                writer.WriteLine();

                writer.WriteLine("=== ВАЖНО ===");
                writer.WriteLine("Все спрайты сохранены в ОРИГИНАЛЬНОМ размере!");
                writer.WriteLine("Масштабирование НЕ применялось.");
                writer.WriteLine();

                writer.WriteLine("=== ПАРАМЕТРЫ УПАКОВКИ ===");
                writer.WriteLine($"Размер спрайт-листа: {sheetWidth} x {sheetHeight} пикселей");
                writer.WriteLine($"Размер ячейки: {cellWidth} x {cellHeight} пикселей (макс. размер спрайта)");
                writer.WriteLine($"Колонок: {columns}");
                writer.WriteLine($"Строк: {totalRows}");
                writer.WriteLine($"Отступ между ячейками: {_config.Padding} пикселей");
                writer.WriteLine($"Режим пиксель-арта: {(_config.PixelArtMode ? "Да" : "Нет")}");
                writer.WriteLine($"Квадратные ячейки: {(_config.UseSquareCells ? "Да" : "Нет")}");
                writer.WriteLine($"Автоопределение колонок: {(_config.AutoColumns ? $"Да (по макс. длине анимации = {maxAnimationLength})" : "Нет")}");
                writer.WriteLine($"Вертикальное выравнивание: {(_config.VerticalAlignment == "bottom" ? "по нижнему краю" : "по центру")}");
                writer.WriteLine();

                writer.WriteLine("=== СТАТИСТИКА ===");
                writer.WriteLine($"Всего анимаций: {animations.Count}");
                writer.WriteLine($"Всего кадров: {sprites.Count}");
                writer.WriteLine($"Среднее количество кадров на анимацию: {(double)sprites.Count / animations.Count:F1}");
                writer.WriteLine($"Максимальная длина анимации: {maxAnimationLength} кадров");

                // Статистика по размерам
                var sizeGroups = sprites.GroupBy(s => $"{s.DrawWidth}x{s.DrawHeight}")
                    .OrderBy(g => g.Key)
                    .ToList();
                writer.WriteLine($"\nРаспределение по размерам спрайтов (оригинальные размеры):");
                foreach (var group in sizeGroups)
                {
                    writer.WriteLine($"  {group.Key}: {group.Count()} спрайтов");
                }
                writer.WriteLine();

                writer.WriteLine("=== АНИМАЦИИ ===");
                foreach (var anim in animations)
                {
                    int rowsUsed = (int)Math.Ceiling((double)anim.Sprites.Count / columns);
                    writer.WriteLine($"\nАнимация: {anim.Name}");
                    writer.WriteLine($"  Количество кадров: {anim.Sprites.Count}");
                    writer.WriteLine($"  Занимает строк: {rowsUsed} из {totalRows}");

                    if (anim.OffsetX != 0 || anim.OffsetY != 0)
                    {
                        writer.WriteLine($"  Смещение анимации: X={anim.OffsetX}, Y={anim.OffsetY} (применено к позиции)");
                    }

                    var sizes = anim.Sprites.Select(s => $"{s.Width}x{s.Height}").Distinct().ToList();
                    writer.WriteLine($"  Размеры кадров: {(sizes.Count == 1 ? sizes[0] : string.Join(", ", sizes))}");

                    writer.WriteLine($"  Кадры:");
                    foreach (var sprite in anim.Sprites)
                    {
                        var position = sprites.First(s => s.Sprite == sprite);
                        writer.WriteLine($"    {sprite.Name}: позиция ({position.X}, {position.Y}), " +
                                       $"размер {sprite.Width}x{sprite.Height}");
                    }
                }

                writer.WriteLine();
                writer.WriteLine("=== КООРДИНАТЫ ДЛЯ ИМПОРТА ===");
                writer.WriteLine("Формат: анимация,кадр,x,y,ширина,высота,смещение_x,смещение_y");
                writer.WriteLine();

                foreach (var anim in animations)
                {
                    writer.WriteLine($"--- {anim.Name} ---");
                    foreach (var sprite in anim.Sprites)
                    {
                        var pos = sprites.First(s => s.Sprite == sprite);
                        writer.WriteLine($"{anim.Name},{sprite.Name},{pos.X},{pos.Y},{sprite.Width},{sprite.Height},{anim.OffsetX},{anim.OffsetY}");
                    }
                    writer.WriteLine();
                }

                writer.WriteLine("=== ПРИМЕЧАНИЯ ПО ИСПОЛЬЗОВАНИЮ ===");
                writer.WriteLine("1. Спрайты сохранены в оригинальном размере - НЕ МАСШТАБИРОВАНЫ");
                writer.WriteLine("2. Для извлечения спрайтов используйте координаты из раздела выше");
                writer.WriteLine("3. Ячейки сетки имеют размер максимального спрайта в упаковке");
                writer.WriteLine("4. Спрайты выровнены по центру горизонтали");
                writer.WriteLine($"5. Вертикальное выравнивание: {(_config.VerticalAlignment == "bottom" ? "по нижнему краю" : "по центру")}");
                writer.WriteLine("6. При работе с пиксель-артом обязательно отключите сглаживание в движке");
                writer.WriteLine("7. Смещения из offset.txt применены к позиции каждого кадра анимации");
                writer.WriteLine("8. Координаты в отчете уже включают примененные смещения");
            }
        }
    }

    public class Config
    {
        public string InputFolder { get; set; } = "sprites";
        public string OutputFolder { get; set; } = "sprites";
        public string OutputImage { get; set; } = "spritesheet.png";
        public int Columns { get; set; } = 0;
        public int Padding { get; set; } = 2;
        public bool PreserveAspectRatio { get; set; } = true;
        public bool PixelArtMode { get; set; } = true;
        public bool UseSquareCells { get; set; } = false;
        public bool AutoColumns { get; set; } = true;
        public string VerticalAlignment { get; set; } = "center";
    }

    public class Sprite
    {
        public string Name { get; set; }
        public Image Image { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public int OriginalWidth { get; set; }
        public int OriginalHeight { get; set; }
        public int X { get; set; }
        public int Y { get; set; }
        public bool Placed { get; set; }
        public string AnimationName { get; set; }
    }

    public class Animation
    {
        public string Name { get; set; }
        public List<Sprite> Sprites { get; set; } = new List<Sprite>();
        public int OffsetX { get; set; } = 0;
        public int OffsetY { get; set; } = 0;
    }

    public class AnimationLayout
    {
        public Animation Animation { get; set; }
        public int Rows { get; set; }
        public int StartRow { get; set; }
    }

    public class SpritePosition
    {
        public Sprite Sprite { get; set; }
        public string AnimationName { get; set; }
        public int Row { get; set; }
        public int Column { get; set; }
        public int X { get; set; }
        public int Y { get; set; }
        public int DrawWidth { get; set; }
        public int DrawHeight { get; set; }
        public int GlobalIndex { get; set; }
        public int OffsetX { get; set; }
        public int OffsetY { get; set; }
    }
}