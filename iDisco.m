#import "iTunes.h"
#import "Cocoa/Cocoa.h"
#include "discord_rpc.h"
#define APPID "393015284115439626"
DiscordRichPresence p = {.largeImageKey = "itunes"};
BOOL reverse, as, tn;
void ready(const DiscordUser* u){
	printf("connected as %s#%s\n", u->username, u->discriminator);
}
void trap(){
	puts("exit");
	Discord_ClearPresence();
	Discord_Shutdown();
	exit(0);
}
void usage(void){
	puts("usage: iDisco [-ran]\n"
		"-r: reverse string order\n"
		"-a: display Artist - Song\n"
		"-n: display tracknumber");
	exit(0);
}
int main(int argc, char **argv){
	signal(SIGINT, trap);
	signal(SIGTERM, trap);
	char ch;
	while((ch = getopt(argc, argv, "ran")) != -1)
		switch(ch){
			case 'r':
				reverse = YES;
				break;
			case 'a':
				as = YES;
				break;
			case 'n':
				tn = YES;
				break;
			default:
				usage();
		};
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
	void (^trackinfo)(NSNotification *) = ^(NSNotification *note){
		if(iTunes.playerState == iTunesEPlSStopped)
			Discord_UpdatePresence(&(DiscordRichPresence){.largeImageKey = "itunes", .state = "Stopped"});
		else{
			BOOL np = iTunes.playerState == iTunesEPlSPlaying;
			iTunesTrack *t = iTunes.currentTrack;
			p.startTimestamp = np?(time_t) difftime(time(NULL), iTunes.playerPosition):0;
			char *top, *bottom;
			if(as){
				top = (char *) [NSString stringWithFormat:@"%@%@ - %@", np?@"":@"⏸️ ", t.artist, t.name].UTF8String;
				bottom = (char *) iTunes.currentTrack.album.UTF8String;
			} else{
				top = (char *) [NSString stringWithFormat:@"%@ - %@", t.artist, t.album].UTF8String;
				bottom = (char *) [NSString stringWithFormat:@"%@%@%@", np?@"":@"⏸️ ", tn?[NSString stringWithFormat:@"%ld. ", t.trackNumber]:@"", t.name].UTF8String;
			}
			if(reverse){
				p.state = bottom;
				p.details = top;
			} else{
				p.state = top;
				p.details = bottom;
			}
			Discord_UpdatePresence(&p);
		};
		Discord_RunCallbacks();
	};
	Discord_Initialize(APPID, &(DiscordEventHandlers){ready, trap, trap}, false, NULL);
	trackinfo(NULL);
	[[NSDistributedNotificationCenter defaultCenter]
		addObserverForName: @"com.apple.iTunes.playerInfo"
		object: nil
		queue: [NSOperationQueue mainQueue]
		usingBlock: trackinfo];
	[[NSRunLoop mainRunLoop] run];
}