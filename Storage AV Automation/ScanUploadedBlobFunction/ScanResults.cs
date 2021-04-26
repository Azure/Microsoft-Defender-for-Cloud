namespace ScanUploadedBlobFunction
{
    public class ScanResults
    {
        public string fileName;
        public bool isThreat;
        public string threatType;

        public ScanResults(
            string fileName = null,
            bool isThreat = false,
            string threatType = null
            )
        {
            this.fileName = fileName;
            this.isThreat = isThreat;
            this.threatType = threatType;
        }
        public string ToString(string separator)
        {
            return "file name: " + this.fileName + separator +
                    "is threat: " + this.isThreat + separator +
                    "threat type: " + this.threatType;
        }
    }
}
