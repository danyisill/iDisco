#include <time.h>
#include "discord_rpc.h"
#import "iTunes.h"
#import "Cocoa/Cocoa.h"
#define APPID "393015284115439626"
#define np ([iTunes playerState] == iTunesEPlSPlaying)

void post(time_t timestamp, NSString *top, NSString *bottom){
	DiscordRichPresence discordPresence;
	memset(&discordPresence, 0, sizeof(discordPresence));
	discordPresence.state = [bottom UTF8String];
	discordPresence.details = [top UTF8String];
	discordPresence.startTimestamp = timestamp;
	discordPresence.largeImageKey = "itunes";
	discordPresence.smallImageKey = "itunes";
	Discord_UpdatePresence(&discordPresence);
	Discord_UpdateConnection();
}
void ready(const DiscordUser *connectedUser){
	printf("connected to %s#%s - %s\n", connectedUser->username, connectedUser->discriminator, connectedUser->userId);
}
void errlog(int e, const char *m){
	printf("disconnected (%d: %s)\n", e, m);
}
void noop(){}
void trap(){
	puts("interrupt");
	Discord_Shutdown();
	exit(0);
}
void init(void){
	DiscordEventHandlers handlers;
	memset(&handlers, 0, sizeof(handlers));
	handlers.ready = ready;
	handlers.disconnected = errlog;
	handlers.errored = errlog;
	handlers.joinGame = noop;
	handlers.spectateGame = noop;
	handlers.joinRequest = noop;
	Discord_Initialize(APPID, &handlers, false, NULL);
	Discord_UpdateConnection();
	Discord_RunCallbacks();
}
int main(void){
	signal(SIGINT, trap);
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	init();
	[[NSDistributedNotificationCenter defaultCenter]
		addObserverForName: @"com.apple.iTunes.playerInfo"
		object: nil
		queue: [NSOperationQueue mainQueue]
		usingBlock: ^(NSNotification *notification) {
			iTunesTrack *cur = [iTunes currentTrack];
			post(np?(time_t) difftime(time(NULL), [iTunes playerPosition]):0,
				[NSString stringWithFormat:@"%@ - %@", [cur artist], [cur album]],
				[NSString stringWithFormat:@"%@%s", [cur name], np?"":" (Paused)"]);
			Discord_RunCallbacks();
		}];
	[[NSRunLoop mainRunLoop] run];
}