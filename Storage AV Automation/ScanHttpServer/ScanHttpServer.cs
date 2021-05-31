using HttpMultipartParser;
using Newtonsoft.Json;
using Serilog;
using Serilog.Exceptions;
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Threading.Tasks;
using System.Reflection;
using System.Linq;

namespace ScanHttpServer
{
    public class ScanHttpServer
    {
        
        private enum requestType { SCAN }

        public static async Task HandleRequestAsync(HttpListenerContext context)
        {
            var request = context.Request;
            var response = context.Response;

            Log.Information("Got new request {requestUrl}", request.Url);
            Log.Information("Raw URL: {requestRawUrl}", request.RawUrl);
            Log.Information("request.ContentType: {requestContentType}", request.ContentType);

            var requestTypeTranslation = new Dictionary<string, requestType>
            {
                { "/scan", requestType.SCAN }
            };

            requestType type = requestTypeTranslation[request.RawUrl];

            switch (type)
            {
                case requestType.SCAN:
                    ScanRequest(request, response);
                    break;
                default:
                    Log.Information("No valid request type");
                    break;
            }
            Log.Information("Done Handling Request {requestUrl}", request.Url);
        }

        public static void ScanRequest(HttpListenerRequest request, HttpListenerResponse response)
        {
            if (!request.ContentType.StartsWith("multipart/form-data", StringComparison.OrdinalIgnoreCase))
            {
                Log.Error("Wrong request Content-type for scanning, {requestContentType}", request.ContentType);
                return;
            };

            var scanner = new WindowsDefenderScanner();
            var parser = MultipartFormDataParser.Parse(request.InputStream);
            var file = parser.Files.First();
            Log.Information("filename: {fileName}", file.FileName);
            string tempFileName = FileUtilities.SaveToTempFile(file.Data);
            if (tempFileName == null)
            {
                Log.Error("Can't save the file received in the request");
                return;
            }

            var result = scanner.Scan(tempFileName);

            if(result.isError)
            {
                Log.Error("Error during the scanning Error message:{errorMessage}", result.errorMessage);

                var data = new
                {
                    ErrorMessage = result.errorMessage,
                };

                SendResponse(response, HttpStatusCode.InternalServerError, data);
                return;
            }

            var responseData = new
            {
                FileName = file.FileName,
                isThreat = result.isThreat,
                ThreatType = result.threatType
            };

            SendResponse(response, HttpStatusCode.OK, responseData);

            try{
                File.Delete(tempFileName);
            }
            catch (Exception e)
            {
                Log.Error(e, "Exception caught when trying to delete temp file:{tempFileName}.", tempFileName);
            }
        }

        private static void SendResponse(
            HttpListenerResponse response,
            HttpStatusCode statusCode,
            object responseData)
        {
            response.StatusCode = (int)statusCode;
            string responseString = JsonConvert.SerializeObject(responseData);
            byte[] buffer = System.Text.Encoding.UTF8.GetBytes(responseString);
            response.ContentLength64 = buffer.Length;
            var responseOutputStream = response.OutputStream;
            try
            {
                responseOutputStream.Write(buffer, 0, buffer.Length);
            }
            finally
            {
                Log.Information("Sending response, {statusCode}:{responseString}", statusCode, responseString);
                responseOutputStream.Close();
            }
        }

        public static void SetUpLogger(string logFileName)
        {
            string runDirPath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            string logFilePath = Path.Combine(runDirPath, "log", logFileName);
            Log.Logger = new LoggerConfiguration()
                .Enrich.WithExceptionDetails()
                .WriteTo.File(logFilePath)
                .WriteTo.Console(restrictedToMinimumLevel: Serilog.Events.LogEventLevel.Error)
                .MinimumLevel.Debug()
                .CreateLogger();
        }

        public static async Task Main(string[] args)
        {
            int port = 4151;
            string[] prefix = {
                $"http://+:{port}/"
            };

            SetUpLogger("ScanHttpServer.log");
            var listener = new HttpListener();

            foreach (string s in prefix)
            {
                listener.Prefixes.Add(s);
            }

            listener.Start();
            Log.Information("Starting ScanHttpServer");

            while (true)
            {
                Log.Information("Waiting for requests...");
                var context = listener.GetContext();
                await HandleRequestAsync(context);
            }
        }
    }
}
