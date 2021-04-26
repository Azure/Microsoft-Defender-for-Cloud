using System;
using System.IO;
using Serilog;

namespace ScanHttpServer
{
    public static class FileUtilities
    {
       public static string SaveToTempFile(Stream fileData)
        {
            string tempFileName = Path.GetTempFileName();
            Log.Information("tmpFileName: {tempFileName}", tempFileName);
            try
            {
                using (var fileStream = File.OpenWrite(tempFileName))
                {
                    fileData.CopyTo(fileStream);
                }
                Log.Information("File created Successfully");
                return tempFileName;
            }
            catch (Exception e)
            {
                Log.Error(e, "Exception caught when trying to save temp file {tempFileName}.", tempFileName);
                throw;
            }
        }
    }
}
