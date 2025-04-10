# To enable ssh & remote debugging on app service change the base image to the one below
# FROM mcr.microsoft.com/azure-functions/powershell:4-powershell7.2-appservice
FROM mcr.microsoft.com/azure-functions/powershell:4-powershell7.2
RUN mkdir /etc/secrets
ENV FUNCTIONS_SECRETS_PATH=/etc/secrets
ENV AzureWebJobsSecretStorageType=Files

COPY . /home/site/wwwroot