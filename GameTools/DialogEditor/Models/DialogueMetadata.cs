using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Text;

namespace DialogEditor.Models
{
    public class DialogueMetadata
    {
        [DisplayName("Глава"), Description("Номер главы")]
        public int Chapter { get; set; } = 1;

        [DisplayName("Уровень"), Description("Название/номер уровня")]
        public string Level { get; set; } = "1-1";

        [DisplayName("Название"), Description("Название сцены")]
        public string Title { get; set; } = "New Scene";

        [DisplayName("Фон"), Description("Путь к фоновому изображению")]
        public string Background { get; set; } = "res://assets/backgrounds/default.png";

        [DisplayName("Музыка"), Description("Путь к музыкальному файлу")]
        public string Music { get; set; } = "res://assets/music/default.ogg";
    }
}