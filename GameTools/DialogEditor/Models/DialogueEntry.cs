using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing.Design;
using System.Text;

namespace DialogEditor.Models
{
    public class DialogueEntry
    {
        [DisplayName("ID"), Description("Уникальный идентификатор диалога")]
        public string Id { get; set; }

        [DisplayName("Говорящий"), Description("Имя персонажа")]
        public string Speaker { get; set; }

        [DisplayName("Текст"), Description("Текст диалога с возможными BB-кодами")]
        public string Text { get; set; }

        [DisplayName("Портрет"), Description("Путь к портрету (res://...)")]
        public string Portrait { get; set; }

        [DisplayName("Звук"), Description("Путь к звуковому файлу (опционально)")]
        public string Sound { get; set; }

        [DisplayName("Методы при старте"), Description("Методы, вызываемые при начале диалога (можно указать несколько через запятую)")]
        public string OnStartMethods { get; set; }

        [DisplayName("Методы при завершении"), Description("Методы, вызываемые при завершении диалога (можно указать несколько через запятую)")]
        public string OnEndMethods { get; set; }

        [DisplayName("Следующий диалог"), Description("ID следующего диалога, пусто если конец")]
        [Editor(typeof(NextIdEditor), typeof(UITypeEditor))]
        public string Next { get; set; }

        [DisplayName("Glitch эффект"), Description("Включить искажение портрета")]
        [DefaultValue(false)]
        public bool GlitchEnabled { get; set; }

        public override string ToString() => $"{Id}: {Speaker} - {(Text?.Length > 50 ? Text.Substring(0, 47) + "..." : Text)}";
    }
}