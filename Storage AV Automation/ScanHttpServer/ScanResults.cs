using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ScanHttpServer
{
    public class ScanResults
    {
        public string fileName { get; set; }
        public bool isThreat { get; set; } = false;
        public string threatType { get; set; }
        public bool isError { get; set; } = false;
        public string errorMessage { get; set; }
    }
}
