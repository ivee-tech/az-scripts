using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using ETSDemo.App.Models;
using ETSDemo.App.Services;
using System.Net.Http;
using System.Net;
using Microsoft.ApplicationInsights;
using Microsoft.Extensions.Caching.Memory;

namespace ETSDemo.App.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly ICalculatorService _calcSvc;
        private readonly TelemetryClient _telemetryClient;
        private readonly IMemoryCache _cache;

        public HomeController(ILogger<HomeController> logger, ICalculatorService calcSvc, TelemetryClient telemetryClient, IMemoryCache cache)
        {
            _logger = logger;
            _calcSvc = calcSvc;
            _telemetryClient = telemetryClient;
            _cache = cache;
        }

        public IActionResult Index()
        {
            _telemetryClient.TrackEvent("homePageRequested");
            return View();
        }

        public IActionResult Privacy()
        {
            return View();
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }

        public IActionResult Calculator()
        {
            return View();
        }

        public async Task<IActionResult> Calculate(string expression)
        {
            if(string.IsNullOrEmpty(expression))
            {
                return BadRequest("Expression is required.");
            }
            var expr = Uri.UnescapeDataString(expression);
            try
            {
                var result = await _calcSvc.Calculate(expr);
                var value = 1;
                _telemetryClient.GetMetric("calcRequests").TrackValue(value);
                _telemetryClient.GetMetric("results").TrackValue(result);
                return Json(result);
            }
            catch(Exception ex)
            {
                return StatusCode((int)HttpStatusCode.InternalServerError, ex.Message);
            }
        }
        public IActionResult GetVisitorCount()
        {
            var visitorCount = 0;
            _cache.TryGetValue(Constants.VisitorCountKey, out visitorCount);
            return Json(visitorCount);
        }
    }
}
