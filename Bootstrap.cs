// ============================================================
// VS Code + Claude Code + CC-Switch Deployment Bootstrapper
// Targets C# 5 (compatible with .NET Framework 4.x csc.exe)
// Compile: csc /target:winexe /out:Setup.exe /resource:resources.zip Bootstrap.cs
// ============================================================
using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Windows.Forms;

class Bootstrap
{
    [STAThread]
    static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        string message = "The following components will be installed:\n\n" +
            "  - Node.js v24.16.0 (Runtime)\n" +
            "  - Visual Studio Code (Editor)\n" +
            "  - Claude Code CLI (AI Assistant)\n" +
            "  - CC-Switch v3.16.0 (API Key Manager)\n\n" +
            "Administrator privileges required. Continue?";

        DialogResult result = MessageBox.Show(
            message,
            "VS Code + Claude Code + CC-Switch Setup",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Question);

        if (result != DialogResult.Yes)
            return;

        try
        {
            string extractPath = Path.Combine(Path.GetTempPath(), "VSCodeClaudeCCSetup");
            CleanDirectory(extractPath);
            Directory.CreateDirectory(extractPath);

            // Try extracting from embedded resource first
            bool extracted = ExtractFromResource(extractPath);

            // Fallback: copy from EXE directory (dev/portable mode)
            if (!extracted)
            {
                ExtractFromExeDirectory(extractPath);
            }

            // Run the installation script
            string ps1Path = Path.Combine(extractPath, "install.ps1");
            if (!File.Exists(ps1Path))
            {
                MessageBox.Show(
                    "Cannot find 'install.ps1'.\n\nPlease ensure all files are present.",
                    "Error",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return;
            }

            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-ExecutionPolicy Bypass -File \"" + ps1Path + "\"",
                UseShellExecute = true,
                Verb = "runas", // Request admin elevation
                WorkingDirectory = extractPath
            };

            Process process = Process.Start(psi);
            if (process != null)
            {
                process.WaitForExit();
                if (process.ExitCode == 0)
                {
                    MessageBox.Show(
                        "All components installed successfully!\n\n" +
                        "Restart your terminal and try:\n" +
                        "  claude    - Launch Claude Code\n" +
                        "  code      - Launch VS Code\n" +
                        "  node -v   - Check Node.js version",
                        "Installation Complete",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Information);
                }
                else
                {
                    MessageBox.Show(
                        "Setup script exited with code: " + process.ExitCode +
                        "\nCheck log: %TEMP%\\cc_setup_log.txt",
                        "Installation May Be Incomplete",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Warning);
                }
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                "Installation error:\n" + ex.Message,
                "Installation Failed",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
    }

    /// <summary>
    /// Extract files from embedded ZIP resource in the assembly
    /// </summary>
    static bool ExtractFromResource(string outputDir)
    {
        Assembly assembly = Assembly.GetExecutingAssembly();
        string[] resourceNames = assembly.GetManifestResourceNames();

        foreach (string name in resourceNames)
        {
            if (name.EndsWith(".zip", StringComparison.OrdinalIgnoreCase)
                || name.IndexOf("resources", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                try
                {
                    using (Stream stream = assembly.GetManifestResourceStream(name))
                    {
                        if (stream == null) continue;

                        string tempZip = Path.Combine(Path.GetTempPath(), "cc_setup_res.zip");
                        using (FileStream fs = new FileStream(tempZip, FileMode.Create, FileAccess.Write))
                        {
                            stream.CopyTo(fs);
                        }

                        try
                        {
                            ZipFile.ExtractToDirectory(tempZip, outputDir);
                            File.Delete(tempZip);
                            return true;
                        }
                        catch
                        {
                            try { File.Delete(tempZip); } catch { }
                        }
                    }
                }
                catch
                {
                    // Try next resource
                }
            }
        }
        return false;
    }

    /// <summary>
    /// Copy files from the EXE's own directory (dev/portable mode)
    /// </summary>
    static void ExtractFromExeDirectory(string outputDir)
    {
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;
        string[] filesToCopy = {
            "install.ps1", "install.bat", "README.md",
            "node-v24.16.0-x64.msi", "CC-Switch-v3.16.0-Windows.msi"
        };

        foreach (string file in filesToCopy)
        {
            string src = Path.Combine(exeDir, file);
            string dst = Path.Combine(outputDir, file);
            if (File.Exists(src) && !File.Exists(dst))
            {
                try { File.Copy(src, dst, true); } catch { }
            }
        }
    }

    /// <summary>
    /// Safely clean a directory
    /// </summary>
    static void CleanDirectory(string path)
    {
        if (!Directory.Exists(path)) return;
        try
        {
            Directory.Delete(path, true);
            for (int i = 0; i < 10 && Directory.Exists(path); i++)
                System.Threading.Thread.Sleep(100);
        }
        catch
        {
            // Directory is in use, ignore
        }
    }
}
