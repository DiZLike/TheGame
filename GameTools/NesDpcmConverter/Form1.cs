using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace NesDpcmConverter
{
    public partial class Form1 : Form
    {
        private readonly string pythonScriptPath = "dpcm.py";

        public Form1()
        {
            InitializeComponent();
            UpdateCurrentSettingsDisplay(null, null);
            this.StartPosition = FormStartPosition.CenterScreen;
        }

        private void BtnBrowseInput_Click(object sender, EventArgs e)
        {
            using (var ofd = new OpenFileDialog())
            {
                ofd.Filter = "WAV files (*.wav)|*.wav|All files (*.*)|*.*";
                ofd.Title = "Select input WAV file";

                if (ofd.ShowDialog() == DialogResult.OK)
                {
                    txtInputFile.Text = ofd.FileName;

                    // Auto-suggest output filename
                    if (string.IsNullOrEmpty(txtOutputFile.Text))
                    {
                        string outputPath = Path.Combine(
                            Path.GetDirectoryName(ofd.FileName),
                            Path.GetFileNameWithoutExtension(ofd.FileName) + "_nes.wav"
                        );
                        txtOutputFile.Text = outputPath;
                    }
                }
            }
        }

        private void BtnBrowseOutput_Click(object sender, EventArgs e)
        {
            using (var sfd = new SaveFileDialog())
            {
                sfd.Filter = "WAV files (*.wav)|*.wav";
                sfd.Title = "Save as...";
                sfd.FileName = Path.GetFileName(txtOutputFile.Text);

                if (sfd.ShowDialog() == DialogResult.OK)
                {
                    txtOutputFile.Text = sfd.FileName;
                }
            }
        }

        private async void BtnConvert_Click(object sender, EventArgs e)
        {
            if (string.IsNullOrEmpty(txtInputFile.Text) || !File.Exists(txtInputFile.Text))
            {
                MessageBox.Show("Please select a valid input WAV file.", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (string.IsNullOrEmpty(txtOutputFile.Text))
            {
                MessageBox.Show("Please specify an output file.", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            if (!File.Exists(pythonScriptPath))
            {
                MessageBox.Show($"Python script '{pythonScriptPath}' not found!\nPlace it in the application folder.",
                    "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            progressBar.Visible = true;
            lblStatus.Text = "Processing...";
            lblStatus.ForeColor = Color.DarkBlue;
            btnConvert.Enabled = false;
            btnTestPython.Enabled = false;

            try
            {
                string arguments = GenerateArguments();

                var psi = new ProcessStartInfo
                {
                    FileName = txtPythonPath.Text,
                    Arguments = $"\"{pythonScriptPath}\" {arguments}",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true,
                    WorkingDirectory = AppDomain.CurrentDomain.BaseDirectory
                };

                using (var p = Process.Start(psi))
                {
                    var outputTask = p.StandardOutput.ReadToEndAsync();
                    var errorTask = p.StandardError.ReadToEndAsync();

                    if (await Task.WhenAny(p.WaitForExitAsync(), Task.Delay(120000)) == Task.Delay(120000))
                    {
                        p.Kill();
                        throw new TimeoutException("Conversion took longer than 120 seconds.");
                    }

                    string stdout = await outputTask;
                    string stderr = await errorTask;

                    if (p.ExitCode == 0)
                    {
                        lblStatus.Text = "Conversion complete.";
                        lblStatus.ForeColor = Color.Green;
                        MessageBox.Show($"Conversion successful!\n\n{stdout}", "Success",
                            MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    else
                    {
                        lblStatus.Text = "Conversion failed.";
                        lblStatus.ForeColor = Color.Red;
                        MessageBox.Show($"Script error:\n\n{stderr}\n\n{stdout}",
                            "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
            catch (Exception ex)
            {
                lblStatus.Text = $"Error: {ex.Message}";
                lblStatus.ForeColor = Color.Red;
                MessageBox.Show($"Error: {ex.Message}", "Error",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                progressBar.Visible = false;
                btnConvert.Enabled = true;
                btnTestPython.Enabled = true;
            }
        }

        private async void BtnTestPython_Click(object sender, EventArgs e)
        {
            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = txtPythonPath.Text,
                    Arguments = "--version",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    CreateNoWindow = true
                };

                using (var p = Process.Start(psi))
                {
                    var output = await p.StandardOutput.ReadToEndAsync();
                    var error = await p.StandardError.ReadToEndAsync();
                    await p.WaitForExitAsync();

                    if (p.ExitCode == 0)
                    {
                        lblStatus.Text = $"Python found: {output.Trim()}";
                        lblStatus.ForeColor = Color.Green;
                    }
                    else
                    {
                        lblStatus.Text = $"Python error: {error}";
                        lblStatus.ForeColor = Color.Red;
                    }
                }
            }
            catch (Exception ex)
            {
                lblStatus.Text = $"Python not found: {ex.Message}";
                lblStatus.ForeColor = Color.Red;
            }
        }

        private void CmbFunction_SelectedIndexChanged(object sender, EventArgs e)
        {
            bool isUltraClean = cmbFunction.SelectedItem.ToString() == "UltraClean";
            bool isStyleEnhanced = cmbFunction.SelectedItem.ToString() == "StyleEnhanced";

            cmbRevision.Enabled = isStyleEnhanced;
            cmbQuality.Enabled = isStyleEnhanced;
            cmbExportMode.Enabled = isStyleEnhanced;
            chkAddArtifacts.Enabled = isStyleEnhanced;
            chkDisableSmoothing.Enabled = isStyleEnhanced;
            chkPreserveTimbre.Enabled = isUltraClean;

            UpdateCurrentSettingsDisplay(null, null);
        }

        private void UpdateCurrentSettingsDisplay(object sender, EventArgs e)
        {
            string function = cmbFunction.SelectedItem?.ToString() ?? "UltraClean";
            string revision = cmbRevision.SelectedItem?.ToString() ?? "standard";
            string quality = cmbQuality.SelectedItem?.ToString() ?? "high";
            string exportMode = cmbExportMode.SelectedItem?.ToString() ?? "safe";
            string artifacts = chkAddArtifacts.Checked ? "Yes" : "No";
            string smoothing = chkDisableSmoothing.Checked ? "Yes (disabled)" : "No";
            string timbre = chkPreserveTimbre.Checked ? "Yes" : "No";

            lblCurrentSettings.Text =
                $"Function: {function}\r\n" +
                $"Revision: {revision}\r\n" +
                $"Quality: {quality}\r\n" +
                $"Export Mode: {exportMode}\r\n" +
                $"Artifacts: {artifacts}\r\n" +
                $"DPCM Smoothing: {smoothing}\r\n" +
                $"NES Timbre: {timbre}";
        }

        private string GenerateArguments()
        {
            string escapedInput = txtInputFile.Text.Replace("\\", "\\\\").Replace("\"", "\\\"");
            string escapedOutput = txtOutputFile.Text.Replace("\\", "\\\\").Replace("\"", "\\\"");
            string function = cmbFunction.SelectedItem.ToString();

            if (function == "UltraClean")
            {
                return $"ultraclean \"{escapedInput}\" \"{escapedOutput}\" {chkPreserveTimbre.Checked.ToString().ToLower()}";
            }
            else if (function == "StyleEnhanced")
            {
                return $"enhanced \"{escapedInput}\" \"{escapedOutput}\" " +
                       $"{cmbRevision.SelectedItem} {cmbQuality.SelectedItem} " +
                       $"{cmbExportMode.SelectedItem} {chkAddArtifacts.Checked.ToString().ToLower()} " +
                       $"{chkDisableSmoothing.Checked.ToString().ToLower()}";
            }
            else // Clean
            {
                return $"clean \"{escapedInput}\" \"{escapedOutput}\"";
            }
        }
    }

    public static class ProcessExtensions
    {
        public static async Task WaitForExitAsync(this Process process)
        {
            var tcs = new TaskCompletionSource<bool>();
            process.EnableRaisingEvents = true;
            process.Exited += (s, e) => tcs.TrySetResult(true);
            if (process.HasExited) tcs.TrySetResult(true);
            await tcs.Task;
        }
    }
}