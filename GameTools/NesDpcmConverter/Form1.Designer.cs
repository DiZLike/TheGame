namespace NesDpcmConverter
{
    partial class Form1
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
            components = new System.ComponentModel.Container();
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Form1));
            toolTip = new ToolTip(components);
            lblInputFile = new Label();
            txtInputFile = new TextBox();
            btnBrowseInput = new Button();
            lblOutputFile = new Label();
            txtOutputFile = new TextBox();
            btnBrowseOutput = new Button();
            lblFunction = new Label();
            lblRevision = new Label();
            lblQuality = new Label();
            lblExportMode = new Label();
            chkPreserveTimbre = new CheckBox();
            chkAddArtifacts = new CheckBox();
            chkDisableSmoothing = new CheckBox();
            lblPythonPath = new Label();
            lblParamsTitle = new Label();
            btnConvert = new Button();
            btnTestPython = new Button();
            mainTableLayout = new TableLayoutPanel();
            leftTableLayout = new TableLayoutPanel();
            lblTitle = new Label();
            inputFileFlowPanel = new FlowLayoutPanel();
            outputFileFlowPanel = new FlowLayoutPanel();
            cmbFunction = new ComboBox();
            cmbRevision = new ComboBox();
            cmbQuality = new ComboBox();
            cmbExportMode = new ComboBox();
            optionsFlowPanel = new FlowLayoutPanel();
            txtPythonPath = new TextBox();
            rightTableLayout = new TableLayoutPanel();
            lblCurrentSettings = new Label();
            bottomFlowPanel = new FlowLayoutPanel();
            buttonFlowPanel = new FlowLayoutPanel();
            progressBar = new ProgressBar();
            lblStatus = new Label();
            mainTableLayout.SuspendLayout();
            leftTableLayout.SuspendLayout();
            inputFileFlowPanel.SuspendLayout();
            outputFileFlowPanel.SuspendLayout();
            optionsFlowPanel.SuspendLayout();
            rightTableLayout.SuspendLayout();
            bottomFlowPanel.SuspendLayout();
            buttonFlowPanel.SuspendLayout();
            SuspendLayout();
            // 
            // toolTip
            // 
            toolTip.AutoPopDelay = 30000;
            toolTip.InitialDelay = 500;
            toolTip.ReshowDelay = 100;
            toolTip.ShowAlways = true;
            toolTip.ToolTipIcon = ToolTipIcon.Info;
            toolTip.ToolTipTitle = "Описание параметра";
            // 
            // lblInputFile
            // 
            lblInputFile.Dock = DockStyle.Fill;
            lblInputFile.Font = new Font("Segoe UI", 9F, FontStyle.Bold);
            lblInputFile.Location = new Point(3, 50);
            lblInputFile.Name = "lblInputFile";
            lblInputFile.Size = new Size(124, 40);
            lblInputFile.TabIndex = 1;
            lblInputFile.Text = "Input WAV";
            lblInputFile.TextAlign = ContentAlignment.MiddleLeft;
            toolTip.SetToolTip(lblInputFile, "Выберите исходный WAV файл для конвертации.\nПоддерживаются моно и стерео файлы.");
            // 
            // txtInputFile
            // 
            txtInputFile.Location = new Point(3, 3);
            txtInputFile.Name = "txtInputFile";
            txtInputFile.Size = new Size(248, 23);
            txtInputFile.TabIndex = 0;
            toolTip.SetToolTip(txtInputFile, "Путь к исходному WAV файлу");
            // 
            // btnBrowseInput
            // 
            btnBrowseInput.Location = new Point(257, 3);
            btnBrowseInput.Name = "btnBrowseInput";
            btnBrowseInput.Size = new Size(30, 23);
            btnBrowseInput.TabIndex = 1;
            btnBrowseInput.Text = "...";
            toolTip.SetToolTip(btnBrowseInput, "Обзор файлов");
            btnBrowseInput.UseVisualStyleBackColor = true;
            btnBrowseInput.Click += BtnBrowseInput_Click;
            // 
            // lblOutputFile
            // 
            lblOutputFile.Dock = DockStyle.Fill;
            lblOutputFile.Font = new Font("Segoe UI", 9F, FontStyle.Bold);
            lblOutputFile.Location = new Point(3, 90);
            lblOutputFile.Name = "lblOutputFile";
            lblOutputFile.Size = new Size(124, 40);
            lblOutputFile.TabIndex = 3;
            lblOutputFile.Text = "Output WAV";
            lblOutputFile.TextAlign = ContentAlignment.MiddleLeft;
            toolTip.SetToolTip(lblOutputFile, "Укажите путь для сохранения результата.\nПо умолчанию: имя_файла_nes.wav");
            // 
            // txtOutputFile
            // 
            txtOutputFile.Location = new Point(3, 3);
            txtOutputFile.Name = "txtOutputFile";
            txtOutputFile.Size = new Size(248, 23);
            txtOutputFile.TabIndex = 0;
            toolTip.SetToolTip(txtOutputFile, "Путь для сохранения обработанного WAV файла");
            // 
            // btnBrowseOutput
            // 
            btnBrowseOutput.Location = new Point(257, 3);
            btnBrowseOutput.Name = "btnBrowseOutput";
            btnBrowseOutput.Size = new Size(30, 23);
            btnBrowseOutput.TabIndex = 1;
            btnBrowseOutput.Text = "...";
            toolTip.SetToolTip(btnBrowseOutput, "Выбрать папку для сохранения");
            btnBrowseOutput.UseVisualStyleBackColor = true;
            btnBrowseOutput.Click += BtnBrowseOutput_Click;
            // 
            // lblFunction
            // 
            lblFunction.Dock = DockStyle.Fill;
            lblFunction.Font = new Font("Segoe UI", 9F, FontStyle.Bold);
            lblFunction.Location = new Point(3, 130);
            lblFunction.Name = "lblFunction";
            lblFunction.Size = new Size(124, 40);
            lblFunction.TabIndex = 5;
            lblFunction.Text = "Function";
            lblFunction.TextAlign = ContentAlignment.MiddleLeft;
            toolTip.SetToolTip(lblFunction, "UltraClean — минимальные артефакты, чистейший звук\nStyleEnhanced — аутентичный звук DPCM-канала NES\nClean — упрощённый режим (StyleEnhanced с оптимальными настройками)");
            // 
            // lblRevision
            // 
            lblRevision.Dock = DockStyle.Fill;
            lblRevision.Font = new Font("Segoe UI", 9F, FontStyle.Bold);
            lblRevision.Location = new Point(3, 170);
            lblRevision.Name = "lblRevision";
            lblRevision.Size = new Size(124, 40);
            lblRevision.TabIndex = 7;
            lblRevision.Text = "Revision";
            lblRevision.TextAlign = ContentAlignment.MiddleLeft;
            toolTip.SetToolTip(lblRevision, "standard — стандартная таблица ЦАП NES (128 значений)\nearly — ранняя ревизия (тише, с компрессией на высоких)\nfamicom — японская Famicom (гамма-коррекция γ=0.95)");
            // 
            // lblQuality
            // 
            lblQuality.Dock = DockStyle.Fill;
            lblQuality.Font = new Font("Segoe UI", 9F, FontStyle.Bold);
            lblQuality.Location = new Point(3, 210);
            lblQuality.Name = "lblQuality";
            lblQuality.Size = new Size(124, 40);
            lblQuality.TabIndex = 9;
            lblQuality.Text = "Quality";
            lblQuality.TextAlign = ContentAlignment.MiddleLeft;
            toolTip.SetToolTip(lblQuality, resources.GetString("lblQuality.ToolTip"));
            // 
            // lblExportMode
            // 
            lblExportMode.Dock = DockStyle.Fill;
            lblExportMode.Font = new Font("Segoe UI", 9F, FontStyle.Bold);
            lblExportMode.Location = new Point(3, 250);
            lblExportMode.Name = "lblExportMode";
            lblExportMode.Size = new Size(124, 40);
            lblExportMode.TabIndex = 11;
            lblExportMode.Text = "Export Mode";
            lblExportMode.TextAlign = ContentAlignment.MiddleLeft;
            toolTip.SetToolTip(lblExportMode, "safe — нормализация до 0.95, мягкое лимитирование tanh\nauthentic — эмуляция перегруза NES (tanh 1.1, нормализация 0.98)\nsoft — компрессия 3:1 с порогом 0.7\nraw — без обработки (может клиппить!)");
            // 
            // chkPreserveTimbre
            // 
            chkPreserveTimbre.AutoSize = true;
            chkPreserveTimbre.Checked = true;
            chkPreserveTimbre.CheckState = CheckState.Checked;
            chkPreserveTimbre.Location = new Point(3, 3);
            chkPreserveTimbre.Name = "chkPreserveTimbre";
            chkPreserveTimbre.Size = new Size(132, 19);
            chkPreserveTimbre.TabIndex = 0;
            chkPreserveTimbre.Text = "Preserve NES timbre";
            toolTip.SetToolTip(chkPreserveTimbre, "Только для UltraClean.\nВключено: применяется tanh(x*1.1) — мягкая нелинейность NES\nВыключено: дополнительное гауссово сглаживание (σ=0.3)");
            chkPreserveTimbre.UseVisualStyleBackColor = true;
            chkPreserveTimbre.CheckedChanged += UpdateCurrentSettingsDisplay;
            // 
            // chkAddArtifacts
            // 
            chkAddArtifacts.AutoSize = true;
            chkAddArtifacts.Checked = true;
            chkAddArtifacts.CheckState = CheckState.Checked;
            chkAddArtifacts.Location = new Point(3, 28);
            chkAddArtifacts.Name = "chkAddArtifacts";
            chkAddArtifacts.Size = new Size(117, 19);
            chkAddArtifacts.TabIndex = 1;
            chkAddArtifacts.Text = "Add NES artifacts";
            toolTip.SetToolTip(chkAddArtifacts, "Только для StyleEnhanced.\nДобавляет фильтрованный шум квантования:\nhigh: 0.0002, medium/low: 0.0005\nЭмулирует шум реального DPCM-канала NES");
            chkAddArtifacts.UseVisualStyleBackColor = true;
            chkAddArtifacts.CheckedChanged += UpdateCurrentSettingsDisplay;
            // 
            // chkDisableSmoothing
            // 
            chkDisableSmoothing.AutoSize = true;
            chkDisableSmoothing.Location = new Point(3, 53);
            chkDisableSmoothing.Name = "chkDisableSmoothing";
            chkDisableSmoothing.Size = new Size(162, 19);
            chkDisableSmoothing.TabIndex = 2;
            chkDisableSmoothing.Text = "Disable DPCM smoothing";
            toolTip.SetToolTip(chkDisableSmoothing, "Только для StyleEnhanced.\nВключено: без сглаживания — резкие переходы (аутентичнее)\nВыключено: гауссово сглаживание согласно качеству (чище)");
            chkDisableSmoothing.UseVisualStyleBackColor = true;
            chkDisableSmoothing.CheckedChanged += UpdateCurrentSettingsDisplay;
            // 
            // lblPythonPath
            // 
            lblPythonPath.Dock = DockStyle.Fill;
            lblPythonPath.Font = new Font("Segoe UI", 9F, FontStyle.Bold);
            lblPythonPath.Location = new Point(3, 390);
            lblPythonPath.Name = "lblPythonPath";
            lblPythonPath.Size = new Size(124, 124);
            lblPythonPath.TabIndex = 14;
            lblPythonPath.Text = "Python Path";
            lblPythonPath.TextAlign = ContentAlignment.MiddleLeft;
            toolTip.SetToolTip(lblPythonPath, "Путь к интерпретатору Python.\nПо умолчанию: python (из PATH)");
            // 
            // lblParamsTitle
            // 
            lblParamsTitle.Dock = DockStyle.Fill;
            lblParamsTitle.Font = new Font("Segoe UI", 12F, FontStyle.Bold);
            lblParamsTitle.ForeColor = Color.FromArgb(60, 60, 60);
            lblParamsTitle.Location = new Point(18, 0);
            lblParamsTitle.Name = "lblParamsTitle";
            lblParamsTitle.Size = new Size(501, 30);
            lblParamsTitle.TabIndex = 0;
            lblParamsTitle.Text = "Current Settings";
            lblParamsTitle.TextAlign = ContentAlignment.MiddleLeft;
            toolTip.SetToolTip(lblParamsTitle, "Наведите курсор на любой параметр слева, чтобы увидеть его описание");
            // 
            // btnConvert
            // 
            btnConvert.BackColor = Color.FromArgb(0, 122, 204);
            btnConvert.FlatStyle = FlatStyle.Flat;
            btnConvert.Font = new Font("Segoe UI", 9F, FontStyle.Bold);
            btnConvert.ForeColor = Color.White;
            btnConvert.Location = new Point(3, 3);
            btnConvert.Name = "btnConvert";
            btnConvert.Size = new Size(110, 35);
            btnConvert.TabIndex = 0;
            btnConvert.Text = "Convert";
            toolTip.SetToolTip(btnConvert, "Запустить преобразование WAV → NES DPCM");
            btnConvert.UseVisualStyleBackColor = false;
            btnConvert.Click += BtnConvert_Click;
            // 
            // btnTestPython
            // 
            btnTestPython.BackColor = Color.FromArgb(230, 230, 230);
            btnTestPython.FlatStyle = FlatStyle.Flat;
            btnTestPython.Font = new Font("Segoe UI", 9F);
            btnTestPython.Location = new Point(119, 3);
            btnTestPython.Name = "btnTestPython";
            btnTestPython.Size = new Size(110, 35);
            btnTestPython.TabIndex = 1;
            btnTestPython.Text = "Test Python";
            toolTip.SetToolTip(btnTestPython, "Проверить доступность Python и версию");
            btnTestPython.UseVisualStyleBackColor = false;
            btnTestPython.Click += BtnTestPython_Click;
            // 
            // mainTableLayout
            // 
            mainTableLayout.ColumnCount = 2;
            mainTableLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 45F));
            mainTableLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 55F));
            mainTableLayout.Controls.Add(leftTableLayout, 0, 0);
            mainTableLayout.Controls.Add(rightTableLayout, 1, 0);
            mainTableLayout.Dock = DockStyle.Fill;
            mainTableLayout.Location = new Point(20, 20);
            mainTableLayout.Name = "mainTableLayout";
            mainTableLayout.RowCount = 1;
            mainTableLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            mainTableLayout.Size = new Size(960, 520);
            mainTableLayout.TabIndex = 0;
            // 
            // leftTableLayout
            // 
            leftTableLayout.ColumnCount = 2;
            leftTableLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 130F));
            leftTableLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            leftTableLayout.Controls.Add(lblTitle, 0, 0);
            leftTableLayout.Controls.Add(lblInputFile, 0, 1);
            leftTableLayout.Controls.Add(inputFileFlowPanel, 1, 1);
            leftTableLayout.Controls.Add(lblOutputFile, 0, 2);
            leftTableLayout.Controls.Add(outputFileFlowPanel, 1, 2);
            leftTableLayout.Controls.Add(lblFunction, 0, 3);
            leftTableLayout.Controls.Add(cmbFunction, 1, 3);
            leftTableLayout.Controls.Add(lblRevision, 0, 4);
            leftTableLayout.Controls.Add(cmbRevision, 1, 4);
            leftTableLayout.Controls.Add(lblQuality, 0, 5);
            leftTableLayout.Controls.Add(cmbQuality, 1, 5);
            leftTableLayout.Controls.Add(lblExportMode, 0, 6);
            leftTableLayout.Controls.Add(cmbExportMode, 1, 6);
            leftTableLayout.Controls.Add(optionsFlowPanel, 1, 7);
            leftTableLayout.Controls.Add(lblPythonPath, 0, 8);
            leftTableLayout.Controls.Add(txtPythonPath, 1, 8);
            leftTableLayout.Dock = DockStyle.Fill;
            leftTableLayout.Location = new Point(3, 3);
            leftTableLayout.Name = "leftTableLayout";
            leftTableLayout.RowCount = 9;
            leftTableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 50F));
            leftTableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 40F));
            leftTableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 40F));
            leftTableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 40F));
            leftTableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 40F));
            leftTableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 40F));
            leftTableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 40F));
            leftTableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 100F));
            leftTableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 40F));
            leftTableLayout.Size = new Size(426, 514);
            leftTableLayout.TabIndex = 0;
            // 
            // lblTitle
            // 
            lblTitle.AutoSize = true;
            leftTableLayout.SetColumnSpan(lblTitle, 2);
            lblTitle.Dock = DockStyle.Fill;
            lblTitle.Font = new Font("Segoe UI", 16F, FontStyle.Bold);
            lblTitle.ForeColor = Color.FromArgb(30, 30, 30);
            lblTitle.Location = new Point(3, 0);
            lblTitle.Name = "lblTitle";
            lblTitle.Size = new Size(420, 50);
            lblTitle.TabIndex = 0;
            lblTitle.Text = "NES DPCM Converter";
            lblTitle.TextAlign = ContentAlignment.MiddleLeft;
            // 
            // inputFileFlowPanel
            // 
            inputFileFlowPanel.Controls.Add(txtInputFile);
            inputFileFlowPanel.Controls.Add(btnBrowseInput);
            inputFileFlowPanel.Dock = DockStyle.Fill;
            inputFileFlowPanel.Location = new Point(133, 53);
            inputFileFlowPanel.Name = "inputFileFlowPanel";
            inputFileFlowPanel.Size = new Size(290, 34);
            inputFileFlowPanel.TabIndex = 2;
            // 
            // outputFileFlowPanel
            // 
            outputFileFlowPanel.Controls.Add(txtOutputFile);
            outputFileFlowPanel.Controls.Add(btnBrowseOutput);
            outputFileFlowPanel.Dock = DockStyle.Fill;
            outputFileFlowPanel.Location = new Point(133, 93);
            outputFileFlowPanel.Name = "outputFileFlowPanel";
            outputFileFlowPanel.Size = new Size(290, 34);
            outputFileFlowPanel.TabIndex = 4;
            // 
            // cmbFunction
            // 
            cmbFunction.Dock = DockStyle.Fill;
            cmbFunction.DropDownStyle = ComboBoxStyle.DropDownList;
            cmbFunction.FormattingEnabled = true;
            cmbFunction.Items.AddRange(new object[] { "UltraClean", "StyleEnhanced", "Clean" });
            cmbFunction.Location = new Point(133, 133);
            cmbFunction.Name = "cmbFunction";
            cmbFunction.Size = new Size(290, 23);
            cmbFunction.TabIndex = 6;
            cmbFunction.SelectedIndexChanged += CmbFunction_SelectedIndexChanged;
            // 
            // cmbRevision
            // 
            cmbRevision.Dock = DockStyle.Fill;
            cmbRevision.DropDownStyle = ComboBoxStyle.DropDownList;
            cmbRevision.FormattingEnabled = true;
            cmbRevision.Items.AddRange(new object[] { "standard", "early", "famicom" });
            cmbRevision.Location = new Point(133, 173);
            cmbRevision.Name = "cmbRevision";
            cmbRevision.Size = new Size(290, 23);
            cmbRevision.TabIndex = 8;
            cmbRevision.SelectedIndexChanged += UpdateCurrentSettingsDisplay;
            // 
            // cmbQuality
            // 
            cmbQuality.Dock = DockStyle.Fill;
            cmbQuality.DropDownStyle = ComboBoxStyle.DropDownList;
            cmbQuality.FormattingEnabled = true;
            cmbQuality.Items.AddRange(new object[] { "high", "medium", "low" });
            cmbQuality.Location = new Point(133, 213);
            cmbQuality.Name = "cmbQuality";
            cmbQuality.Size = new Size(290, 23);
            cmbQuality.TabIndex = 10;
            cmbQuality.SelectedIndexChanged += UpdateCurrentSettingsDisplay;
            // 
            // cmbExportMode
            // 
            cmbExportMode.Dock = DockStyle.Fill;
            cmbExportMode.DropDownStyle = ComboBoxStyle.DropDownList;
            cmbExportMode.FormattingEnabled = true;
            cmbExportMode.Items.AddRange(new object[] { "safe", "authentic", "soft", "raw" });
            cmbExportMode.Location = new Point(133, 253);
            cmbExportMode.Name = "cmbExportMode";
            cmbExportMode.Size = new Size(290, 23);
            cmbExportMode.TabIndex = 12;
            cmbExportMode.SelectedIndexChanged += UpdateCurrentSettingsDisplay;
            // 
            // optionsFlowPanel
            // 
            optionsFlowPanel.Controls.Add(chkPreserveTimbre);
            optionsFlowPanel.Controls.Add(chkAddArtifacts);
            optionsFlowPanel.Controls.Add(chkDisableSmoothing);
            optionsFlowPanel.Dock = DockStyle.Fill;
            optionsFlowPanel.FlowDirection = FlowDirection.TopDown;
            optionsFlowPanel.Location = new Point(133, 293);
            optionsFlowPanel.Name = "optionsFlowPanel";
            optionsFlowPanel.Size = new Size(290, 94);
            optionsFlowPanel.TabIndex = 13;
            // 
            // txtPythonPath
            // 
            txtPythonPath.Dock = DockStyle.Fill;
            txtPythonPath.Location = new Point(133, 393);
            txtPythonPath.Name = "txtPythonPath";
            txtPythonPath.Size = new Size(290, 23);
            txtPythonPath.TabIndex = 15;
            txtPythonPath.Text = "python";
            // 
            // rightTableLayout
            // 
            rightTableLayout.ColumnCount = 1;
            rightTableLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            rightTableLayout.Controls.Add(lblParamsTitle, 0, 0);
            rightTableLayout.Controls.Add(lblCurrentSettings, 0, 1);
            rightTableLayout.Dock = DockStyle.Fill;
            rightTableLayout.Location = new Point(435, 3);
            rightTableLayout.Name = "rightTableLayout";
            rightTableLayout.Padding = new Padding(15, 0, 0, 0);
            rightTableLayout.RowCount = 2;
            rightTableLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 30F));
            rightTableLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            rightTableLayout.Size = new Size(522, 514);
            rightTableLayout.TabIndex = 1;
            // 
            // lblCurrentSettings
            // 
            lblCurrentSettings.BackColor = Color.FromArgb(250, 250, 250);
            lblCurrentSettings.BorderStyle = BorderStyle.FixedSingle;
            lblCurrentSettings.Dock = DockStyle.Fill;
            lblCurrentSettings.Font = new Font("Consolas", 10F);
            lblCurrentSettings.Location = new Point(18, 30);
            lblCurrentSettings.Name = "lblCurrentSettings";
            lblCurrentSettings.Padding = new Padding(15);
            lblCurrentSettings.Size = new Size(501, 484);
            lblCurrentSettings.TabIndex = 1;
            lblCurrentSettings.Text = resources.GetString("lblCurrentSettings.Text");
            // 
            // bottomFlowPanel
            // 
            bottomFlowPanel.Controls.Add(buttonFlowPanel);
            bottomFlowPanel.Controls.Add(lblStatus);
            bottomFlowPanel.Dock = DockStyle.Bottom;
            bottomFlowPanel.Location = new Point(20, 540);
            bottomFlowPanel.Name = "bottomFlowPanel";
            bottomFlowPanel.Padding = new Padding(0, 10, 0, 0);
            bottomFlowPanel.Size = new Size(960, 60);
            bottomFlowPanel.TabIndex = 1;
            // 
            // buttonFlowPanel
            // 
            buttonFlowPanel.AutoSize = true;
            buttonFlowPanel.Controls.Add(btnConvert);
            buttonFlowPanel.Controls.Add(btnTestPython);
            buttonFlowPanel.Controls.Add(progressBar);
            buttonFlowPanel.Location = new Point(0, 10);
            buttonFlowPanel.Margin = new Padding(0, 0, 20, 0);
            buttonFlowPanel.Name = "buttonFlowPanel";
            buttonFlowPanel.Size = new Size(360, 41);
            buttonFlowPanel.TabIndex = 0;
            // 
            // progressBar
            // 
            progressBar.Location = new Point(235, 3);
            progressBar.Name = "progressBar";
            progressBar.Size = new Size(122, 35);
            progressBar.Style = ProgressBarStyle.Marquee;
            progressBar.TabIndex = 2;
            progressBar.Visible = false;
            // 
            // lblStatus
            // 
            lblStatus.AutoSize = true;
            lblStatus.Font = new Font("Segoe UI", 9F);
            lblStatus.ForeColor = Color.Gray;
            lblStatus.Location = new Point(400, 20);
            lblStatus.Margin = new Padding(20, 10, 0, 0);
            lblStatus.Name = "lblStatus";
            lblStatus.Size = new Size(39, 15);
            lblStatus.TabIndex = 1;
            lblStatus.Text = "Ready";
            // 
            // Form1
            // 
            AutoScaleDimensions = new SizeF(7F, 15F);
            AutoScaleMode = AutoScaleMode.Font;
            BackColor = Color.White;
            ClientSize = new Size(1000, 620);
            Controls.Add(mainTableLayout);
            Controls.Add(bottomFlowPanel);
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;
            Name = "Form1";
            Padding = new Padding(20);
            StartPosition = FormStartPosition.CenterScreen;
            Text = "NES DPCM Converter";
            mainTableLayout.ResumeLayout(false);
            leftTableLayout.ResumeLayout(false);
            leftTableLayout.PerformLayout();
            inputFileFlowPanel.ResumeLayout(false);
            inputFileFlowPanel.PerformLayout();
            outputFileFlowPanel.ResumeLayout(false);
            outputFileFlowPanel.PerformLayout();
            optionsFlowPanel.ResumeLayout(false);
            optionsFlowPanel.PerformLayout();
            rightTableLayout.ResumeLayout(false);
            bottomFlowPanel.ResumeLayout(false);
            bottomFlowPanel.PerformLayout();
            buttonFlowPanel.ResumeLayout(false);
            ResumeLayout(false);
        }

        // === Control Declarations ===
        private System.Windows.Forms.ToolTip toolTip;

        private System.Windows.Forms.TableLayoutPanel mainTableLayout;
        private System.Windows.Forms.TableLayoutPanel leftTableLayout;
        private System.Windows.Forms.TableLayoutPanel rightTableLayout;
        private System.Windows.Forms.FlowLayoutPanel bottomFlowPanel;
        private System.Windows.Forms.FlowLayoutPanel buttonFlowPanel;
        private System.Windows.Forms.FlowLayoutPanel inputFileFlowPanel;
        private System.Windows.Forms.FlowLayoutPanel outputFileFlowPanel;
        private System.Windows.Forms.FlowLayoutPanel optionsFlowPanel;

        private System.Windows.Forms.Label lblTitle;
        private System.Windows.Forms.Label lblInputFile;
        private System.Windows.Forms.Label lblOutputFile;
        private System.Windows.Forms.Label lblFunction;
        private System.Windows.Forms.Label lblRevision;
        private System.Windows.Forms.Label lblQuality;
        private System.Windows.Forms.Label lblExportMode;
        private System.Windows.Forms.Label lblPythonPath;
        private System.Windows.Forms.Label lblStatus;
        private System.Windows.Forms.Label lblParamsTitle;
        private System.Windows.Forms.Label lblCurrentSettings;

        private System.Windows.Forms.TextBox txtInputFile;
        private System.Windows.Forms.TextBox txtOutputFile;
        private System.Windows.Forms.TextBox txtPythonPath;

        private System.Windows.Forms.ComboBox cmbFunction;
        private System.Windows.Forms.ComboBox cmbRevision;
        private System.Windows.Forms.ComboBox cmbQuality;
        private System.Windows.Forms.ComboBox cmbExportMode;

        private System.Windows.Forms.CheckBox chkPreserveTimbre;
        private System.Windows.Forms.CheckBox chkAddArtifacts;
        private System.Windows.Forms.CheckBox chkDisableSmoothing;

        private System.Windows.Forms.Button btnBrowseInput;
        private System.Windows.Forms.Button btnBrowseOutput;
        private System.Windows.Forms.Button btnConvert;
        private System.Windows.Forms.Button btnTestPython;

        private System.Windows.Forms.ProgressBar progressBar;
    }
}