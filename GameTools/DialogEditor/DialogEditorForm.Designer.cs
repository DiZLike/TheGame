using DialogEditor.Models;

namespace DialogEditor
{
    partial class DialogEditorForm
    {
        private System.ComponentModel.IContainer components = null;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            openFileDialog = new OpenFileDialog();
            saveFileDialog = new SaveFileDialog();
            toolStrip = new ToolStrip();
            btnLoad = new ToolStripButton();
            btnSave = new ToolStripButton();
            btnSaveAs = new ToolStripButton();
            toolStripSeparator1 = new ToolStripSeparator();
            btnAdd = new ToolStripButton();
            btnCopy = new ToolStripButton();
            btnDelete = new ToolStripButton();
            toolStripSeparator2 = new ToolStripSeparator();
            btnValidateLinks = new ToolStripButton();
            toolStripSeparator3 = new ToolStripSeparator();
            btnRefreshPreview = new ToolStripButton();
            splitContainer = new SplitContainer();
            dgvDialogues = new DataGridView();
            tabControl = new TabControl();
            tabProperties = new TabPage();
            propertyGrid = new PropertyGrid();
            tabMetadata = new TabPage();
            metadataGrid = new PropertyGrid();
            tabJsonPreview = new TabPage();
            txtJsonPreview = new TextBox();
            statusStrip = new StatusStrip();
            statusLabel = new ToolStripStatusLabel();
            toolStrip.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)splitContainer).BeginInit();
            splitContainer.Panel1.SuspendLayout();
            splitContainer.Panel2.SuspendLayout();
            splitContainer.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)dgvDialogues).BeginInit();
            tabControl.SuspendLayout();
            tabProperties.SuspendLayout();
            tabMetadata.SuspendLayout();
            tabJsonPreview.SuspendLayout();
            statusStrip.SuspendLayout();
            SuspendLayout();
            // 
            // openFileDialog
            // 
            openFileDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*";
            openFileDialog.Title = "Загрузить файл диалогов";
            // 
            // saveFileDialog
            // 
            saveFileDialog.Filter = "JSON files (*.json)|*.json|All files (*.*)|*.*";
            saveFileDialog.Title = "Сохранить файл диалогов";
            // 
            // toolStrip
            // 
            toolStrip.Items.AddRange(new ToolStripItem[] { btnLoad, btnSave, btnSaveAs, toolStripSeparator1, btnAdd, btnCopy, btnDelete, toolStripSeparator2, btnValidateLinks, toolStripSeparator3, btnRefreshPreview });
            toolStrip.Location = new Point(0, 0);
            toolStrip.Name = "toolStrip";
            toolStrip.Size = new Size(924, 25);
            toolStrip.TabIndex = 0;
            toolStrip.Text = "toolStrip";
            // 
            // btnLoad
            // 
            btnLoad.DisplayStyle = ToolStripItemDisplayStyle.Text;
            btnLoad.Name = "btnLoad";
            btnLoad.Size = new Size(96, 22);
            btnLoad.Text = "Загрузить JSON";
            btnLoad.Click += BtnLoad_Click;
            // 
            // btnSave
            // 
            btnSave.DisplayStyle = ToolStripItemDisplayStyle.Text;
            btnSave.Name = "btnSave";
            btnSave.Size = new Size(100, 22);
            btnSave.Text = "Сохранить JSON";
            btnSave.Click += BtnSave_Click;
            // 
            // btnSaveAs
            // 
            btnSaveAs.DisplayStyle = ToolStripItemDisplayStyle.Text;
            btnSaveAs.Name = "btnSaveAs";
            btnSaveAs.Size = new Size(128, 22);
            btnSaveAs.Text = "Сохранить JSON как...";
            btnSaveAs.Click += BtnSaveAs_Click;
            // 
            // toolStripSeparator1
            // 
            toolStripSeparator1.Name = "toolStripSeparator1";
            toolStripSeparator1.Size = new Size(6, 25);
            // 
            // btnAdd
            // 
            btnAdd.DisplayStyle = ToolStripItemDisplayStyle.Text;
            btnAdd.Name = "btnAdd";
            btnAdd.Size = new Size(104, 22);
            btnAdd.Text = "Добавить диалог";
            btnAdd.Click += BtnAdd_Click;
            // 
            // btnCopy
            // 
            btnCopy.DisplayStyle = ToolStripItemDisplayStyle.Text;
            btnCopy.Name = "btnCopy";
            btnCopy.Size = new Size(117, 22);
            btnCopy.Text = "Копировать диалог";
            btnCopy.Click += BtnCopy_Click;
            // 
            // btnDelete
            // 
            btnDelete.DisplayStyle = ToolStripItemDisplayStyle.Text;
            btnDelete.Name = "btnDelete";
            btnDelete.Size = new Size(96, 22);
            btnDelete.Text = "Удалить диалог";
            btnDelete.Click += BtnDelete_Click;
            // 
            // toolStripSeparator2
            // 
            toolStripSeparator2.Name = "toolStripSeparator2";
            toolStripSeparator2.Size = new Size(6, 25);
            // 
            // btnValidateLinks
            // 
            btnValidateLinks.DisplayStyle = ToolStripItemDisplayStyle.Text;
            btnValidateLinks.Name = "btnValidateLinks";
            btnValidateLinks.Size = new Size(115, 22);
            btnValidateLinks.Text = "Проверить ссылки";
            btnValidateLinks.Click += BtnValidateLinks_Click;
            // 
            // toolStripSeparator3
            // 
            toolStripSeparator3.Name = "toolStripSeparator3";
            toolStripSeparator3.Size = new Size(6, 25);
            // 
            // btnRefreshPreview
            // 
            btnRefreshPreview.DisplayStyle = ToolStripItemDisplayStyle.Text;
            btnRefreshPreview.Name = "btnRefreshPreview";
            btnRefreshPreview.Size = new Size(106, 22);
            btnRefreshPreview.Text = "Обновить Preview";
            btnRefreshPreview.Click += BtnRefreshPreview_Click;
            // 
            // splitContainer
            // 
            splitContainer.Dock = DockStyle.Fill;
            splitContainer.Location = new Point(0, 25);
            splitContainer.Margin = new Padding(4, 3, 4, 3);
            splitContainer.Name = "splitContainer";
            // 
            // splitContainer.Panel1
            // 
            splitContainer.Panel1.Controls.Add(dgvDialogues);
            // 
            // splitContainer.Panel2
            // 
            splitContainer.Panel2.Controls.Add(tabControl);
            splitContainer.Size = new Size(924, 493);
            splitContainer.SplitterDistance = 550;
            splitContainer.SplitterWidth = 5;
            splitContainer.TabIndex = 1;
            // 
            // dgvDialogues
            // 
            dgvDialogues.AllowUserToAddRows = false;
            dgvDialogues.AllowUserToDeleteRows = false;
            dgvDialogues.AllowUserToResizeRows = false;
            dgvDialogues.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            dgvDialogues.Dock = DockStyle.Fill;
            dgvDialogues.EnableHeadersVisualStyles = false;
            dgvDialogues.Location = new Point(0, 0);
            dgvDialogues.Margin = new Padding(4, 3, 4, 3);
            dgvDialogues.MultiSelect = false;
            dgvDialogues.Name = "dgvDialogues";
            dgvDialogues.RowHeadersVisible = false;
            dgvDialogues.RowHeadersWidthSizeMode = DataGridViewRowHeadersWidthSizeMode.DisableResizing;
            dgvDialogues.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            dgvDialogues.Size = new Size(550, 493);
            dgvDialogues.TabIndex = 0;
            dgvDialogues.SelectionChanged += DgvDialogues_SelectionChanged;
            // 
            // tabControl
            // 
            tabControl.Controls.Add(tabProperties);
            tabControl.Controls.Add(tabMetadata);
            tabControl.Controls.Add(tabJsonPreview);
            tabControl.Dock = DockStyle.Fill;
            tabControl.Location = new Point(0, 0);
            tabControl.Margin = new Padding(4, 3, 4, 3);
            tabControl.Name = "tabControl";
            tabControl.SelectedIndex = 0;
            tabControl.Size = new Size(369, 493);
            tabControl.TabIndex = 0;
            // 
            // tabProperties
            // 
            tabProperties.Controls.Add(propertyGrid);
            tabProperties.Location = new Point(4, 24);
            tabProperties.Margin = new Padding(4, 3, 4, 3);
            tabProperties.Name = "tabProperties";
            tabProperties.Padding = new Padding(4, 3, 4, 3);
            tabProperties.Size = new Size(361, 465);
            tabProperties.TabIndex = 0;
            tabProperties.Text = "Свойства диалога";
            tabProperties.UseVisualStyleBackColor = true;
            // 
            // propertyGrid
            // 
            propertyGrid.Dock = DockStyle.Fill;
            propertyGrid.Location = new Point(4, 3);
            propertyGrid.Margin = new Padding(4, 3, 4, 3);
            propertyGrid.Name = "propertyGrid";
            propertyGrid.PropertySort = PropertySort.Categorized;
            propertyGrid.Size = new Size(353, 459);
            propertyGrid.TabIndex = 0;
            // 
            // tabMetadata
            // 
            tabMetadata.Controls.Add(metadataGrid);
            tabMetadata.Location = new Point(4, 24);
            tabMetadata.Margin = new Padding(4, 3, 4, 3);
            tabMetadata.Name = "tabMetadata";
            tabMetadata.Padding = new Padding(4, 3, 4, 3);
            tabMetadata.Size = new Size(361, 465);
            tabMetadata.TabIndex = 1;
            tabMetadata.Text = "Метаданные";
            tabMetadata.UseVisualStyleBackColor = true;
            // 
            // metadataGrid
            // 
            metadataGrid.Dock = DockStyle.Fill;
            metadataGrid.Location = new Point(4, 3);
            metadataGrid.Margin = new Padding(4, 3, 4, 3);
            metadataGrid.Name = "metadataGrid";
            metadataGrid.PropertySort = PropertySort.Categorized;
            metadataGrid.Size = new Size(353, 459);
            metadataGrid.TabIndex = 0;
            // 
            // tabJsonPreview
            // 
            tabJsonPreview.Controls.Add(txtJsonPreview);
            tabJsonPreview.Location = new Point(4, 24);
            tabJsonPreview.Margin = new Padding(4, 3, 4, 3);
            tabJsonPreview.Name = "tabJsonPreview";
            tabJsonPreview.Padding = new Padding(4, 3, 4, 3);
            tabJsonPreview.Size = new Size(361, 465);
            tabJsonPreview.TabIndex = 2;
            tabJsonPreview.Text = "JSON Preview";
            tabJsonPreview.UseVisualStyleBackColor = true;
            // 
            // txtJsonPreview
            // 
            txtJsonPreview.Dock = DockStyle.Fill;
            txtJsonPreview.Font = new Font("Consolas", 9F);
            txtJsonPreview.Location = new Point(4, 3);
            txtJsonPreview.Margin = new Padding(4, 3, 4, 3);
            txtJsonPreview.Multiline = true;
            txtJsonPreview.Name = "txtJsonPreview";
            txtJsonPreview.ReadOnly = true;
            txtJsonPreview.ScrollBars = ScrollBars.Both;
            txtJsonPreview.Size = new Size(353, 459);
            txtJsonPreview.TabIndex = 0;
            txtJsonPreview.WordWrap = false;
            // 
            // statusStrip
            // 
            statusStrip.Items.AddRange(new ToolStripItem[] { statusLabel });
            statusStrip.Location = new Point(0, 518);
            statusStrip.Name = "statusStrip";
            statusStrip.Padding = new Padding(1, 0, 16, 0);
            statusStrip.Size = new Size(924, 22);
            statusStrip.TabIndex = 2;
            statusStrip.Text = "statusStrip";
            // 
            // statusLabel
            // 
            statusLabel.Name = "statusLabel";
            statusLabel.Size = new Size(907, 17);
            statusLabel.Spring = true;
            statusLabel.Text = "Готов";
            statusLabel.TextAlign = System.Drawing.ContentAlignment.MiddleLeft;
            // 
            // DialogEditorForm
            // 
            AutoScaleDimensions = new SizeF(7F, 15F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(924, 540);
            Controls.Add(splitContainer);
            Controls.Add(toolStrip);
            Controls.Add(statusStrip);
            Margin = new Padding(4, 3, 4, 3);
            MinimumSize = new Size(800, 500);
            Name = "DialogEditorForm";
            StartPosition = FormStartPosition.CenterScreen;
            Text = "Редактор диалогов v2.0";
            toolStrip.ResumeLayout(false);
            toolStrip.PerformLayout();
            splitContainer.Panel1.ResumeLayout(false);
            splitContainer.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)splitContainer).EndInit();
            splitContainer.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)dgvDialogues).EndInit();
            tabControl.ResumeLayout(false);
            tabProperties.ResumeLayout(false);
            tabMetadata.ResumeLayout(false);
            tabJsonPreview.ResumeLayout(false);
            tabJsonPreview.PerformLayout();
            statusStrip.ResumeLayout(false);
            statusStrip.PerformLayout();
            ResumeLayout(false);
            PerformLayout();
        }
    }
}