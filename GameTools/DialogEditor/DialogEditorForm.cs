using DialogEditor.Models;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Windows.Forms;
using Timer = System.Windows.Forms.Timer;

namespace DialogEditor
{
    public partial class DialogEditorForm : Form
    {
        private DialogueData dialogueData;
        private BindingList<DialogueEntry> dialoguesBinding;
        private string currentFilePath = null; // Для отслеживания текущего файла

        // Объявляем контролы
        protected DataGridView dgvDialogues;
        protected PropertyGrid propertyGrid;
        protected TextBox txtJsonPreview;
        protected ToolStripButton btnLoad, btnSave, btnSaveAs, btnAdd, btnCopy, btnDelete, btnValidateLinks, btnRefreshPreview;
        protected OpenFileDialog openFileDialog;
        protected SaveFileDialog saveFileDialog;
        protected SplitContainer splitContainer;
        protected TabControl tabControl;
        protected PropertyGrid metadataGrid;
        protected ToolStrip toolStrip;
        protected TabPage tabProperties;
        protected TabPage tabMetadata;
        protected TabPage tabJsonPreview;
        protected StatusStrip statusStrip;
        protected ToolStripStatusLabel statusLabel;
        protected ToolStripSeparator toolStripSeparator1;
        protected ToolStripSeparator toolStripSeparator2;
        protected ToolStripSeparator toolStripSeparator3;

        public DialogEditorForm()
        {
            InitializeComponent();
            InitializeData();
        }

        private void InitializeData()
        {
            dialogueData = new DialogueData
            {
                Dialogues = new List<DialogueEntry>(),
                Metadata = new DialogueMetadata()
            };
            dialoguesBinding = new BindingList<DialogueEntry>();
            dgvDialogues.DataSource = dialoguesBinding;

            // Настройка отображения колонок
            ConfigureDataGridViewColumns();
        }

        // Метод для получения всех ID диалогов (используется NextIdEditor)
        public List<string> GetAllDialogueIds()
        {
            return dialoguesBinding.Select(d => d.Id).Where(id => !string.IsNullOrEmpty(id)).ToList();
        }

        private void ConfigureDataGridViewColumns()
        {
            if (dgvDialogues.Columns.Count > 0)
            {
                // Настройка видимости и ширины колонок
                if (dgvDialogues.Columns["Id"] != null)
                    dgvDialogues.Columns["Id"].Width = 120;
                if (dgvDialogues.Columns["Speaker"] != null)
                    dgvDialogues.Columns["Speaker"].Width = 100;
                if (dgvDialogues.Columns["Text"] != null)
                    dgvDialogues.Columns["Text"].Width = 200;
                if (dgvDialogues.Columns["OnStartMethods"] != null)
                    dgvDialogues.Columns["OnStartMethods"].Width = 120;
                if (dgvDialogues.Columns["OnEndMethods"] != null)
                    dgvDialogues.Columns["OnEndMethods"].Width = 120;
                if (dgvDialogues.Columns["Next"] != null)
                    dgvDialogues.Columns["Next"].Width = 100;
                if (dgvDialogues.Columns["GlitchEnabled"] != null)
                    dgvDialogues.Columns["GlitchEnabled"].Width = 80;

                // Скрываем редко используемые колонки для экономии места
                if (dgvDialogues.Columns["Portrait"] != null)
                    dgvDialogues.Columns["Portrait"].Visible = false;
                if (dgvDialogues.Columns["Sound"] != null)
                    dgvDialogues.Columns["Sound"].Visible = false;
            }
        }

        private void BtnLoad_Click(object sender, EventArgs e)
        {
            using (var openDialog = new OpenFileDialog())
            {
                openDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*";
                openDialog.Title = "Загрузить файл диалогов";

                if (openDialog.ShowDialog() == DialogResult.OK)
                {
                    LoadFromFile(openDialog.FileName);
                }
            }
        }

        private void LoadFromFile(string filePath)
        {
            try
            {
                string json = File.ReadAllText(filePath);
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true,
                    Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                };

                var loadedData = JsonSerializer.Deserialize<DialogueData>(json, options);

                if (loadedData == null)
                    loadedData = new DialogueData();

                if (loadedData.Dialogues == null)
                    loadedData.Dialogues = new List<DialogueEntry>();

                if (loadedData.Metadata == null)
                    loadedData.Metadata = new DialogueMetadata();

                dialogueData = loadedData;

                dialoguesBinding.Clear();
                foreach (var dialog in dialogueData.Dialogues)
                    dialoguesBinding.Add(dialog);

                if (metadataGrid != null)
                    metadataGrid.SelectedObject = dialogueData.Metadata;

                currentFilePath = filePath;
                RefreshJsonPreview();
                UpdateStatus($"Загружено {dialogueData.Dialogues.Count} диалогов из {Path.GetFileName(filePath)}", true);
            }
            catch (Exception ex)
            {
                UpdateStatus($"Ошибка загрузки: {ex.Message}", false);
                MessageBox.Show($"Ошибка загрузки: {ex.Message}", "Ошибка", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnSave_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(currentFilePath))
            {
                BtnSaveAs_Click(sender, e);
            }
            else
            {
                SaveToFile(currentFilePath);
            }
        }

        private void BtnSaveAs_Click(object sender, EventArgs e)
        {
            using (var saveDialog = new SaveFileDialog())
            {
                saveDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*";
                saveDialog.Title = "Сохранить файл диалогов";
                saveDialog.FileName = currentFilePath != null ? Path.GetFileName(currentFilePath) : "dialogues.json";

                if (saveDialog.ShowDialog() == DialogResult.OK)
                {
                    SaveToFile(saveDialog.FileName);
                }
            }
        }

        private void SaveToFile(string filePath)
        {
            try
            {
                dialogueData.Dialogues = dialoguesBinding.ToList();
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                };
                string json = JsonSerializer.Serialize(dialogueData, options);
                File.WriteAllText(filePath, json, Encoding.UTF8);

                currentFilePath = filePath;
                UpdateStatus($"Файл сохранён: {Path.GetFileName(filePath)}", true);
                RefreshJsonPreview();

                MessageBox.Show("Файл успешно сохранён", "Сохранение", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                UpdateStatus($"Ошибка сохранения: {ex.Message}", false);
                MessageBox.Show($"Ошибка сохранения: {ex.Message}", "Ошибка", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void BtnAdd_Click(object sender, EventArgs e)
        {
            var newDialog = new DialogueEntry
            {
                Id = GenerateUniqueId("new_dialogue"),
                Speaker = "Новый персонаж",
                Text = "Текст диалога",
                Portrait = "",
                Sound = "",
                OnStartMethods = "",
                OnEndMethods = "",
                Next = "",
                GlitchEnabled = false
            };
            dialoguesBinding.Add(newDialog);

            // Выбираем новый диалог
            int newIndex = dialoguesBinding.Count - 1;
            if (newIndex >= 0 && newIndex < dgvDialogues.Rows.Count)
            {
                dgvDialogues.ClearSelection();
                dgvDialogues.Rows[newIndex].Selected = true;
                dgvDialogues.FirstDisplayedScrollingRowIndex = newIndex;
            }

            UpdateStatus($"Добавлен диалог: {newDialog.Id}", true);
            RefreshJsonPreview();
        }

        private void BtnCopy_Click(object sender, EventArgs e)
        {
            if (dgvDialogues.SelectedRows.Count == 0)
            {
                MessageBox.Show("Сначала выберите диалог для копирования",
                    "Нет выделения", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            var original = dgvDialogues.SelectedRows[0].DataBoundItem as DialogueEntry;
            if (original == null) return;

            var copy = new DialogueEntry
            {
                Id = GenerateUniqueId(original.Id),
                Speaker = original.Speaker,
                Text = original.Text,
                Portrait = original.Portrait,
                Sound = original.Sound,
                OnStartMethods = original.OnStartMethods,
                OnEndMethods = original.OnEndMethods,
                Next = original.Next,
                GlitchEnabled = original.GlitchEnabled
            };

            dialoguesBinding.Add(copy);

            int newIndex = dialoguesBinding.Count - 1;
            dgvDialogues.ClearSelection();
            if (newIndex >= 0 && newIndex < dgvDialogues.Rows.Count)
            {
                dgvDialogues.Rows[newIndex].Selected = true;
                dgvDialogues.FirstDisplayedScrollingRowIndex = newIndex;
            }

            UpdateStatus($"Скопирован диалог: {original.Id} -> {copy.Id}", true);
            RefreshJsonPreview();
        }

        private void BtnDelete_Click(object sender, EventArgs e)
        {
            if (dgvDialogues.SelectedRows.Count > 0)
            {
                var selected = dgvDialogues.SelectedRows[0].DataBoundItem as DialogueEntry;
                if (selected != null && MessageBox.Show($"Удалить диалог '{selected.Id}'?", "Подтверждение",
                    MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                {
                    dialoguesBinding.Remove(selected);
                    RefreshJsonPreview();
                    UpdateStatus($"Удалён диалог: {selected.Id}", true);
                }
            }
        }

        private void BtnValidateLinks_Click(object sender, EventArgs e)
        {
            var dialogues = dialoguesBinding.ToList();

            if (dialogues.Count == 0)
            {
                MessageBox.Show("Нет диалогов для проверки", "Проверка ссылок",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            var existingIds = new HashSet<string>(dialogues.Select(d => d.Id).Where(id => !string.IsNullOrEmpty(id)));

            var missingLinks = new List<string>();
            var selfLinks = new List<string>();

            foreach (var dialog in dialogues)
            {
                if (string.IsNullOrWhiteSpace(dialog.Next))
                {
                    continue;
                }

                if (dialog.Next == dialog.Id)
                {
                    selfLinks.Add($"{dialog.Id} -> {dialog.Next}");
                }

                if (!existingIds.Contains(dialog.Next))
                {
                    missingLinks.Add($"{dialog.Id} -> {dialog.Next} (не существует)");
                }
            }

            var circularPaths = FindCircularReferences(dialogues, existingIds);

            var referencedIds = new HashSet<string>();
            foreach (var dialog in dialogues)
            {
                if (!string.IsNullOrWhiteSpace(dialog.Next))
                    referencedIds.Add(dialog.Next);
            }

            var unreferenced = dialogues.Where(d => !referencedIds.Contains(d.Id))
                                        .Select(d => d.Id)
                                        .ToList();

            var report = new StringBuilder();
            report.AppendLine("=== ОТЧЁТ О ПРОВЕРКЕ ССЫЛОК ===");
            report.AppendLine();
            report.AppendLine($"Всего диалогов: {dialogues.Count}");
            report.AppendLine($"Существующих ID: {existingIds.Count}");
            report.AppendLine();

            var dialoguesWithOnStart = dialogues.Where(d => !string.IsNullOrWhiteSpace(d.OnStartMethods)).ToList();
            var dialoguesWithOnEnd = dialogues.Where(d => !string.IsNullOrWhiteSpace(d.OnEndMethods)).ToList();
            var dialoguesWithGlitch = dialogues.Where(d => d.GlitchEnabled).ToList();

            if (dialoguesWithOnStart.Count > 0)
            {
                report.AppendLine("📢 ДИАЛОГИ С OnStartMethods:");
                foreach (var dialog in dialoguesWithOnStart)
                    report.AppendLine($"   • {dialog.Id}: {dialog.OnStartMethods}");
                report.AppendLine();
            }

            if (dialoguesWithOnEnd.Count > 0)
            {
                report.AppendLine("🔚 ДИАЛОГИ С OnEndMethods:");
                foreach (var dialog in dialoguesWithOnEnd)
                    report.AppendLine($"   • {dialog.Id}: {dialog.OnEndMethods}");
                report.AppendLine();
            }

            if (dialoguesWithGlitch.Count > 0)
            {
                report.AppendLine("📺 ДИАЛОГИ С GLITCH ЭФФЕКТОМ:");
                foreach (var dialog in dialoguesWithGlitch)
                    report.AppendLine($"   • {dialog.Id}");
                report.AppendLine();
            }

            if (missingLinks.Count > 0)
            {
                report.AppendLine("❌ НЕСУЩЕСТВУЮЩИЕ ССЫЛКИ:");
                foreach (var link in missingLinks)
                    report.AppendLine($"   • {link}");
                report.AppendLine();
            }

            if (selfLinks.Count > 0)
            {
                report.AppendLine("⚠️ ССЫЛКИ НА СЕБЯ (потенциальная проблема):");
                foreach (var link in selfLinks)
                    report.AppendLine($"   • {link}");
                report.AppendLine();
            }

            if (circularPaths.Count > 0)
            {
                report.AppendLine("🔄 ОБНАРУЖЕНЫ ЦИКЛИЧЕСКИЕ ССЫЛКИ:");
                foreach (var cycle in circularPaths)
                    report.AppendLine($"   • {cycle}");
                report.AppendLine();
            }

            if (unreferenced.Count > 0)
            {
                report.AppendLine("📌 НЕИСПОЛЬЗУЕМЫЕ ДИАЛОГИ (возможно, мёртвый код):");
                foreach (var id in unreferenced.Take(20))
                    report.AppendLine($"   • {id}");
                if (unreferenced.Count > 20)
                    report.AppendLine($"   • ... и ещё {unreferenced.Count - 20} диалогов");
                report.AppendLine();
            }

            if (missingLinks.Count == 0 && selfLinks.Count == 0 && circularPaths.Count == 0)
            {
                report.AppendLine("✅ ОШИБОК НЕ ОБНАРУЖЕНО!");
                report.AppendLine("Все ссылки корректны.");
            }

            ShowReportWindow(report.ToString());
            UpdateStatus("Проверка ссылок завершена", true);
        }

        private List<string> FindCircularReferences(List<DialogueEntry> dialogues, HashSet<string> existingIds)
        {
            var cycles = new List<string>();
            var visited = new HashSet<string>();
            var path = new Stack<string>();

            foreach (var dialog in dialogues)
            {
                if (!visited.Contains(dialog.Id))
                {
                    DetectCycle(dialog.Id, dialogues, existingIds, visited, path, cycles);
                }
            }

            return cycles.Distinct().ToList();
        }

        private void DetectCycle(string startId, List<DialogueEntry> dialogues, HashSet<string> existingIds,
                                 HashSet<string> visited, Stack<string> path, List<string> cycles)
        {
            if (path.Contains(startId))
            {
                var cycleList = new List<string>();
                bool found = false;

                foreach (var p in path.Reverse())
                {
                    if (p == startId)
                        found = true;
                    if (found)
                        cycleList.Add(p);
                }
                cycleList.Reverse();
                cycleList.Add(startId);
                cycles.Add(string.Join(" -> ", cycleList));
                return;
            }

            if (visited.Contains(startId))
                return;

            visited.Add(startId);
            path.Push(startId);

            var dialog = dialogues.FirstOrDefault(d => d.Id == startId);
            if (dialog != null && !string.IsNullOrWhiteSpace(dialog.Next) && existingIds.Contains(dialog.Next))
            {
                DetectCycle(dialog.Next, dialogues, existingIds, visited, path, cycles);
            }

            path.Pop();
        }

        private void ShowReportWindow(string report)
        {
            var reportForm = new Form
            {
                Text = "Результат проверки ссылок",
                Size = new Size(700, 500),
                StartPosition = FormStartPosition.CenterParent
            };

            var textBox = new TextBox
            {
                Dock = DockStyle.Fill,
                Multiline = true,
                ScrollBars = ScrollBars.Both,
                Font = new Font("Consolas", 10),
                ReadOnly = true,
                Text = report
            };

            var panel = new Panel { Dock = DockStyle.Bottom, Height = 40 };

            var btnClose = new Button
            {
                Text = "Закрыть",
                Location = new Point(panel.Width - 100, 5),
                Size = new Size(90, 30),
                BackColor = Color.LightGray,
                Anchor = AnchorStyles.Top | AnchorStyles.Right
            };
            btnClose.Click += (s, e) => reportForm.Close();

            var btnCopyReport = new Button
            {
                Text = "Копировать отчёт",
                Location = new Point(panel.Width - 200, 5),
                Size = new Size(90, 30),
                BackColor = Color.LightGray,
                Anchor = AnchorStyles.Top | AnchorStyles.Right
            };
            btnCopyReport.Click += (s, e) =>
            {
                Clipboard.SetText(report);
                MessageBox.Show("Отчёт скопирован в буфер обмена", "Копирование",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
            };

            panel.Controls.Add(btnCopyReport);
            panel.Controls.Add(btnClose);

            // Обновляем позицию кнопок при изменении размера панели
            panel.Resize += (s, e) =>
            {
                btnClose.Location = new Point(panel.Width - 100, 5);
                btnCopyReport.Location = new Point(panel.Width - 200, 5);
            };

            reportForm.Controls.Add(textBox);
            reportForm.Controls.Add(panel);

            reportForm.ShowDialog(this);
        }

        private void DgvDialogues_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvDialogues.SelectedRows.Count > 0 && dgvDialogues.SelectedRows[0].DataBoundItem != null)
            {
                var selected = dgvDialogues.SelectedRows[0].DataBoundItem as DialogueEntry;
                if (propertyGrid != null)
                    propertyGrid.SelectedObject = selected;
            }
            else
            {
                if (propertyGrid != null)
                    propertyGrid.SelectedObject = null;
            }
        }

        private void BtnRefreshPreview_Click(object sender, EventArgs e)
        {
            RefreshJsonPreview();
            UpdateStatus("JSON превью обновлено", true);
        }

        private void RefreshJsonPreview()
        {
            if (txtJsonPreview == null) return;

            var tempData = new DialogueData
            {
                Dialogues = dialoguesBinding.ToList(),
                Metadata = dialogueData?.Metadata ?? new DialogueMetadata()
            };

            var options = new JsonSerializerOptions
            {
                WriteIndented = true,
                Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
            };

            string json = JsonSerializer.Serialize(tempData, options);
            txtJsonPreview.Text = json;
        }

        private string GenerateUniqueId(string baseId)
        {
            string cleanBase = baseId;
            if (cleanBase.Contains("_copy"))
            {
                cleanBase = cleanBase.Split(new[] { "_copy" }, StringSplitOptions.None)[0];
            }

            string newId = $"{cleanBase}_copy";
            int counter = 1;

            while (dialoguesBinding.Any(d => d.Id == newId))
            {
                newId = $"{cleanBase}_copy{counter}";
                counter++;
            }

            return newId;
        }

        private void UpdateStatus(string message, bool isSuccess)
        {
            if (statusLabel != null)
            {
                statusLabel.Text = message;
                statusLabel.ForeColor = isSuccess ? SystemColors.ControlText : Color.Red;
            }

            // Автоматически сбрасываем цвет через 3 секунды
            if (isSuccess)
            {
                var timer = new Timer();
                timer.Interval = 3000;
                timer.Tick += (s, e) =>
                {
                    if (statusLabel != null)
                        statusLabel.ForeColor = SystemColors.ControlText;
                    timer.Stop();
                    timer.Dispose();
                };
                timer.Start();
            }
        }
    }
}