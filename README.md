# eSport Brande Intranet API
API for eSport Brande Intranet page (currently Private Repo). Making for a Dynamic and Interactive experience on our Intranet site, using APIs and Azure Functions.

## Getting Started
Modify the `.env` file to set up your environment variables. You can use the `.env.example` file as a template

### Create a API key in Pterodactyl: 
1.  Login to Pterodactyl Panel
2.  Go to your account settings
3.  Click on "API Keys" in the left sidebar
4.  Click on "Create API Key"
5.  Fill in the required fields (name, description, etc.)
6.  Add it to the `.env` file as `pterodactylApikey` and add the URL to `pterodactylApiUrl` (format: "https://panel.example.com/api/")

### Azure Function specfic setup
1. `CORS_ALLOWED_ORIGINS` is a comma-separated list of allowed origins. For example: `["https://url1.com", "https://url2.com"]`