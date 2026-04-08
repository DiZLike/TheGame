using System;
using System.ComponentModel;
using System.Drawing.Design;
using System.Windows.Forms;
using System.Windows.Forms.Design;
using DialogEditor.Models;

namespace DialogEditor
{
    public class NextIdEditor : UITypeEditor
    {
        public override UITypeEditorEditStyle GetEditStyle(ITypeDescriptorContext context)
        {
            return UITypeEditorEditStyle.DropDown;
        }

        public override object EditValue(ITypeDescriptorContext context, IServiceProvider provider, object value)
        {
            if (context?.Instance is DialogueEntry entry && provider != null)
            {
                var editorService = (IWindowsFormsEditorService)provider.GetService(typeof(IWindowsFormsEditorService));
                if (editorService != null)
                {
                    var listBox = new ListBox();
                    listBox.Items.Add(""); // Пустое значение (конец диалога)
                    listBox.Items.Add("(КОНЕЦ ДИАЛОГА)"); // Наглядное обозначение конца

                    // Ищем форму редактора через контекст
                    var form = FindParentForm(context);
                    if (form is DialogEditorForm editorForm)
                    {
                        foreach (var id in editorForm.GetAllDialogueIds())
                        {
                            if (!string.IsNullOrEmpty(id))
                                listBox.Items.Add(id);
                        }
                    }

                    // Выбираем текущее значение
                    string currentValue = value?.ToString() ?? "";
                    if (string.IsNullOrEmpty(currentValue))
                        listBox.SelectedItem = "";
                    else if (listBox.Items.Contains(currentValue))
                        listBox.SelectedItem = currentValue;

                    listBox.Height = Math.Min(300, listBox.Items.Count * 20);

                    listBox.Click += (s, e) =>
                    {
                        string selected = listBox.SelectedItem?.ToString() ?? "";
                        // Если выбран маркер конца, возвращаем пустую строку
                        if (selected == "(КОНЕЦ ДИАЛОГА)")
                            selected = "";
                        value = selected;
                        editorService.CloseDropDown();
                    };

                    editorService.DropDownControl(listBox);
                }
            }
            return value;
        }

        private Form FindParentForm(ITypeDescriptorContext context)
        {
            // Пытаемся найти форму через сервис
            if (context?.GetService(typeof(Form)) is Form form)
                return form;

            // Альтернативный способ: ищем через контекст экземпляра
            if (context?.Instance != null)
            {
                var field = context.Instance.GetType().GetField("parent",
                    System.Reflection.BindingFlags.NonPublic |
                    System.Reflection.BindingFlags.Instance |
                    System.Reflection.BindingFlags.Public);
                if (field?.GetValue(context.Instance) is Form form2)
                    return form2;
            }
            return null;
        }
    }
}