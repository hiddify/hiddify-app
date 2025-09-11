#ifndef LIBCORE_H
#define LIBCORE_H

#ifdef __cplusplus
extern "C" {
#endif

// Core setup and configuration functions
void setupOnce(void* api);
char* setup(char* baseDir, char* workingDir, char* tempDir, long long statusPort, int debug);
char* parse(char* configPath, char* tempPath, int debug);
char* changeHiddifyOptions(char* hiddifyOptionsJson);
char* generateConfig(char* configPath);

// Service control functions
char* start(char* configPath, int disableMemoryLimit);
char* stop(void);
char* restart(char* configPath, int disableMemoryLimit);

// Command client functions
char* startCommandClient(int command, long long port);
char* stopCommandClient(int command);

// Outbound management functions
char* selectOutbound(char* groupTag, char* outboundTag);
char* urlTest(char* groupTag);

// Configuration generation functions
char* generateWarpConfig(char* licenseKey, char* accountId, char* accessToken);

#ifdef __cplusplus
}
#endif

#endif // LIBCORE_H 