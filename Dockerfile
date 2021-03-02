FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-buster-slim


MAINTAINER Rhythm Raj
WORKDIR /app


COPY WebApplication4/app/rhythmraj .
ENTRYPOINT ["dotnet", "WebApplication4.dll"]