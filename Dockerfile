FROM microsoft/dotnet:2.2.0-aspnetcore-runtime AS base
WORKDIR /app
EXPOSE 80

FROM microsoft/dotnet:2.2.100-sdk AS build
WORKDIR /src
COPY . .
WORKDIR /src/Marketing.API
RUN dotnet restore -nowarn:msb3202,nu1503
RUN dotnet build --no-restore -c Release -o /app

FROM build as functionaltest
WORKDIR /src/Marketing.FunctionalTests

FROM build AS publish
RUN dotnet publish --no-restore -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
RUN mkdir -p /opt/appdynamics/dotnet
ADD appd/libappdprofiler.so /opt/appdynamics/dotnet/
ADD appd/AppDynamics.Agent.netstandard.dll /opt/appdynamics/dotnet/
# Mandatory settings required to attach the agent to the .NET application
ENV CORECLR_PROFILER={57e1aa68-2229-41aa-9931-a6e93bbc64d8} \
    CORECLR_ENABLE_PROFILING=1 \
    CORECLR_PROFILER_PATH=/opt/appdynamics/dotnet/libappdprofiler.so
ENTRYPOINT ["dotnet", "Marketing.API.dll"]
