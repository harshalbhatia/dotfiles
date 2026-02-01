// ~/.finicky.js
module.exports = {
  defaultBrowser: "company.thebrowser.dia",
  options: {
    urlShorteners: ["nam12.safelinks.protection.outlook.com"],
  },
  handlers: [
    // Glassdoor links
    {
      match: ({ url }) => url.host.includes("glassdoor"),
      browser: "Google Chrome",
    },

    // LinkedIn job links (matches job-specific LinkedIn URLs but not all LinkedIn)
    {
      match: ({ url }) => {
        return (
          url.host.includes("linkedin.com") &&
          (url.pathname.includes("/jobs/") ||
            url.pathname.includes("/job/") ||
            url.search.includes("currentJobId"))
        );
      },
      browser: "Google Chrome",
    },

    // Workday links (common patterns for Workday job applications)
    {
      match: ({ url }) => {
        // Match various Workday domains and patterns
        return (
          // Match direct workday.com domains
          url.host.includes("workday.com") ||
          // Match company.workday.com subdomains
          /^[\w-]+\.workday\.com$/.test(url.host) ||
          // Match myworkday domains
          url.host.includes("myworkday.com") ||
          // Match URLs with workday in the path (common for embedded Workday portals)
          url.pathname.includes("/workday/") ||
          // Common Workday application paths
          (url.pathname.includes("/careers/") &&
            url.pathname.includes("/apply/")) ||
          // Match URLs with typical Workday URL parameters
          url.search.includes("workdayApplicationId")
        );
      },
      browser: "Google Chrome",
    },
  ],
};
