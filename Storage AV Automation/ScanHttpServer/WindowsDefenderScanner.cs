using System;
using System.Diagnostics;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Serilog;

namespace ScanHttpServer
{
    public class WindowsDefenderScanner
    {
        private const  string ScanningLineStart = "Scanning";
        private const string ThreatTypeLineStart = "Threat";
        private const string ErrorLineStart = "CmdTool:";
        private const string OutputErrorLineStart = "ERROR";
        private static readonly string internalErrorMassage = "Internal Server Error";
        private static readonly string MoCmdRunPath = @"C:\Program Files\Windows Defender\MpCmdRun.exe";
        public ScanResults Scan(string fileFullPath)
        {
            Log.Information("Start Scanning {fileFullPath}", fileFullPath);

            string prefixArgs = @" -Scan -ScanType 3 -File ";
            string suffixArgs = " -DisableRemediation";

            string scanProcessOutput = RunScannerProcess(prefixArgs + fileFullPath + suffixArgs).GetAwaiter().GetResult();
            if(scanProcessOutput == null)
            {
                return new ScanResults() { isError = true, errorMessage = internalErrorMassage };
            }
            Log.Information("Scanning output {scanProcessOutput}", scanProcessOutput);
            return ParseScanOutput(scanProcessOutput);
        }


        private async Task<string> RunScannerProcess(string arguments)
        {
            Log.Information("command executed: \n{command}", MoCmdRunPath + arguments);
            var process = new Process();
            process.StartInfo.FileName = MoCmdRunPath;
            process.StartInfo.Arguments = arguments;
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;

            try
            {
                process.Start();
                await process.WaitForExitAsync();
                string proccesOutput = process.StandardOutput.ReadToEnd();
                return proccesOutput;
            }
            catch (Exception e)
            {
                Log.Error(e, "Exception caught when trying to start the scanner process.");
                throw;
            }
        }

        private ScanResults ParseScanOutput(string scanProcessOutput)
        {
            Log.Information("Parsing scan output");
            string resultString = Regex.Replace(scanProcessOutput, @"^\s*$\n|\r", string.Empty, RegexOptions.Multiline).TrimEnd();
            var linesArray = resultString.Split(new[] { '\r', '\n' });
            var result = new ScanResults() { isError=false };

            foreach (string line in linesArray)
            {
                ReadScanOutputLine(result, line);
            }

            if (result.isError)
            {
                result.errorMessage = scanProcessOutput;
            }
            Log.Information("Done Parsing scan Output");
            return result;
        }

        private static void ReadScanOutputLine(ScanResults result, string line)
        {
            var words = line.Split(' ');
            switch (words[0])
            {
                case ScanningLineStart:
                    if (words.Length < 2)
                    {
                        Log.Error("Error trying to parse scan results, Scanning line contain only one word");
                        result.isError = true;
                        return;
                    }

                    if (int.TryParse(words[^2], out var numOfThreatsFound))
                    {
                        result.isThreat = true;
                        break;
                    }
                    else
                    {
                        result.isThreat = false;
                        return;
                    }
                    
                case ThreatTypeLineStart:
                    result.threatType = String.Join(' ', words.Skip(1));
                    return;

                case ErrorLineStart:
                    result.isError = true;
                    return;
            }
        }
    }
}
