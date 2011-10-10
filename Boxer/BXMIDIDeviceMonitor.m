/* 
 Boxer is copyright 2011 Alun Bestor and contributors.
 Boxer is released under the GNU General Public License 2.0. A full copy of this license can be
 found in this XCode project at Resources/English.lproj/BoxerHelp/pages/legalese.html, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */

#import "BXMIDIDeviceMonitor.h"
#import "BXMIDIConstants.h"


//How long (in seconds) Boxer will wait before giving up on a response from a MIDI device.
#define BXMIDIInputListenerDefaultTimeout 1


#pragma mark -
#pragma mark Private method declarations

@interface BXMIDIDeviceMonitor()

//The message we send to MIDI devices to check if they're MT-32s.
//This is an MT-32-specific message requesting an arbitrary byte value
//from the MT-32's patch bank: no other MIDI device should respond to
//this request.
+ (NSData *) _MT32IdentityRequest;

//The response stub we need to receive from a MIDI device to identify
//it as being an MT-32.
+ (NSData *) _MT32ExpectedResponseHeader;

//Called when a CoreMIDI event notification is received (e.g. a device
//connection or disconnection.)
void _didReceiveMIDINotification(const MIDINotification *message, void *context);
- (void) _MIDINotificationReceived: (const MIDINotification *)message;

//Scan the specified MIDI destination for an MT-32.
- (void) _scanDestination: (MIDIEndpointRef)destination;

//Scan all currently-connected destinations for MT-32s.
- (void) _scanAvailableDestinations;

//Returns the currently-active listener for the specified source,
//or nil if no listener is found.
- (BXMIDIInputListener *) _listenerForSource: (MIDIEndpointRef)source;

//Returns our best guess at the MIDI source corresponding to the specified destination. 
//This will first try to find an available source on the same entity as the destination,
//falling back on any available source in the system. (Skips sources we're already
//listening to on behalf of other destinations, as this would otherwise lead to mixups
//where we wouldn't be able to tell which destination a message is for.)
- (MIDIEndpointRef) _probableSourceForDestination: (MIDIEndpointRef)destination;

@end


#pragma mark -
#pragma mark Implementation

@implementation BXMIDIDeviceMonitor
@synthesize discoveredMT32s = _discoveredMT32s;

#pragma mark -
#pragma mark Public API

//Because we may be writing to discoveredMT32s at the same time as it's accessed,
//we synchronize it and return a copy to the calling context.
- (NSArray *) discoveredMT32s
{
    NSArray *MT32s;
    @synchronized(_discoveredMT32s)
    {
        MT32s = [[NSArray alloc] initWithArray: _discoveredMT32s copyItems: YES];
    }
    return [MT32s autorelease];
}

- (id) init
{
    if ((self = [super init]))
    {
        //Create our listeners pool and MT-32 results pool
        _listeners = [[NSMutableArray alloc] initWithCapacity: 1];
        _discoveredMT32s = [[NSMutableArray alloc] initWithCapacity: 1];
    }
    return self;
}

- (void) main
{
    //Bail out early if we've already been cancelled.
    if ([self isCancelled]) return;
    
    _thread = [NSThread currentThread];
    
    //Create a MIDI client
    OSStatus errCode = MIDIClientCreate((CFStringRef)@"Boxer MT-32 Scanner", _didReceiveMIDINotification, self, &_client);
    
    //Create the port we will use for sending out MIDI requests.
    if (errCode == noErr)
    {
        errCode = MIDIOutputPortCreate(_client, (CFStringRef)@"MT-32 Scanner Out", &_outputPort);
    }
    
    //Create the port we will use for receiving responses to our MIDI requests.
    if (errCode == noErr)
    {
        _inputPort = [BXMIDIInputListener createListeningPortForClient: _client
                                                              withName: @"MT-32 Scanner In"
                                                                 error: NULL];
    }
    
    //If we created everything we need, start browsing for devices.
    if (![self isCancelled] && _client && _outputPort && _inputPort)
    {
        //Begin by scanning any already-connected MIDI destinations.
        [self _scanAvailableDestinations];
        
        //Keep the operation running until we're cancelled,
        //listening for MIDI device connections and disconnections.
        while (![self isCancelled] && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
                                                               beforeDate: [NSDate distantFuture]]);
        
    }
    //Clean up once we're done.
    MIDIClientDispose(_client);
    _client = NULL;
    _thread = nil;
}

- (void) cancel
{
    //Make sure cancel requests are handled on our own operation thread,
    //so that the thread's runloop will return upstairs in main.
    if (_thread && [NSThread currentThread] != _thread)
    {
        [self performSelector: _cmd onThread: _thread withObject: nil waitUntilDone: NO];
    }
    else
    {
        [super cancel];
    }
}

- (void) dealloc
{
    [_listeners release], _listeners = nil;
    [_discoveredMT32s release], _discoveredMT32s = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark Request constants

+ (NSData *) _MT32IdentityRequest
{
    static NSData *request = nil;
    if (!request)
    {
#define BXMT32IdentityRequestLength 13
        const UInt8 requestContent[BXMT32IdentityRequestLength] = {
            BXSysexStart,
            
            //Sysex is addressed to MT-32
            BXSysexManufacturerIDRoland, BXRolandSysexDeviceIDDefault, BXRolandSysexModelIDMT32,
            
            BXRolandSysexDataRequest,
            
            0x05, 0x00, 0x00, //Ask for value from the patch memory
            
            0x00, 0x00, 0x01, //Ask for 1 byte only please
            
            0x7A, //Checksum
            
            BXSysexEnd
        };
        
        request = [[NSData alloc] initWithBytes: requestContent
                                         length: BXMT32IdentityRequestLength];
    }
    return request;
}

+ (NSData *) _MT32ExpectedResponseHeader
{
    static NSData *response = nil;
    if (!response)
    {
#define BXMT32IdentityResponseLength 4
        const UInt8 responseContent[BXMT32IdentityResponseLength] = {
            BXSysexStart,
            //Sysex comes from MT-32
            BXSysexManufacturerIDRoland, BXRolandSysexDeviceIDDefault, BXRolandSysexModelIDMT32
            //We don't care about the rest of the message beyond this
        };
        
        response = [[NSData alloc] initWithBytes: responseContent
                                          length: BXMT32IdentityResponseLength];
    }
    return response;
}


#pragma mark -
#pragma mark MIDI event handling

void _didReceiveMIDINotification(const MIDINotification *message, void *context)
{
    [(BXMIDIDeviceMonitor *)context _MIDINotificationReceived: message];
}

- (void) _MIDINotificationReceived: (const MIDINotification *)message
{
    NSLog(@"MIDI notification received of type %ld", message->messageID);
    
    //If a new destination was added, start scanning it.
    if (message->messageID == kMIDIMsgObjectAdded)
    {
        MIDIObjectAddRemoveNotification *notification = (MIDIObjectAddRemoveNotification *)message;
        
        if (notification->childType == kMIDIObjectType_Destination)
        {
            MIDIEndpointRef destination = (MIDIEndpointRef)notification->child;
            NSLog(@"Scanning newly-connected MIDI destination");
            [self _scanDestination: destination];
        }
    }
    
    //If a source or destination we're listening to was removed, then clean up the listener
    //(and remove it from our array of MT-32 matches, if found.)
    else if (message->messageID == kMIDIMsgObjectRemoved)
    {
        MIDIObjectAddRemoveNotification *notification = (MIDIObjectAddRemoveNotification *)message;
        
        MIDIObjectType type = notification->childType;
        if (type == kMIDIObjectType_Destination || type == kMIDIObjectType_Source)
        {
            MIDIEndpointRef endpoint = (MIDIEndpointRef)notification->child;
            
            if (type == kMIDIObjectType_Destination)
                NSLog(@"Cleaning up disconnected MIDI destination");
            else
                NSLog(@"Cleaning up disconnected MIDI source");
            
            for (BXMIDIInputListener *listener in [NSArray arrayWithArray: _listeners])
            {
                if ((type == kMIDIObjectType_Destination && [listener contextInfo] == endpoint) ||
                    (type == kMIDIObjectType_Source && [listener source] == endpoint))
                {
                    [listener stopListening];
                    [_listeners removeObject: listener];
                }
            }
            
            if (type == kMIDIObjectType_Destination)
            {
                MIDIUniqueID destinationID;
                OSStatus errCode = MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &destinationID);
                if (errCode == noErr)
                {
                    NSNumber *storedID = [NSNumber numberWithInteger: destinationID];
                    if ([_discoveredMT32s containsObject: storedID])
                    {
                        //Synchronize to avoid problems if another thread is currently accessing the MT-32 list.
                        @synchronized(_discoveredMT32s)
                        {
                            NSMutableArray *mutableDestinations = [self mutableArrayValueForKey: @"discoveredMT32s"];
                            [mutableDestinations removeObject: storedID];
                        }
                    }
                }
            }
        }
    }
}

- (void) MIDIInputListener: (BXMIDIInputListener *)listener
              receivedData: (NSData *)data
{
    NSData *fullResponse = [listener receivedData];
    NSData *expectedHeader = [[self class] _MT32ExpectedResponseHeader];
    
    //If we've received enough of a response to be able to tell, search
    //the data we've received to see if it contains our expected response.
    if ([fullResponse length] >= [expectedHeader length])
    {
        NSData *comparison = [fullResponse subdataWithRange: NSMakeRange(0, [expectedHeader length])];
        //We have a winner!
        if ([comparison isEqualToData: expectedHeader])
        {
            MIDIEndpointRef destination = (MIDIEndpointRef)[listener contextInfo];
            MIDIUniqueID destinationID;
            
            OSErr errCode = MIDIObjectGetIntegerProperty(destination, kMIDIPropertyUniqueID, &destinationID);
            
            if (errCode == noErr)
            {
                NSLog(@"MT-32 found at destination ID %ld", destinationID);
                
                //Synchronize to avoid problems if another thread is currently accessing the MT-32 list.
                @synchronized(_discoveredMT32s)
                {
                    NSMutableArray *mutableDestinations = [self mutableArrayValueForKey: @"discoveredMT32s"];
                    [mutableDestinations addObject: [NSNumber numberWithInteger: destinationID]];
                }
            }
        }
        else
        {
            NSLog(@"Non-matching response from MIDI device: %@", fullResponse);
        }
        
        //After establishing whether or not it's an MT-32, disconnect from this device.
        [listener stopListening];
        [_listeners removeObject: listener];
    }
}

- (BOOL) MIDIInputListenerShouldStopListeningAfterTimeout: (BXMIDIInputListener *)listener
{
    NSLog(@"MIDI input listener timed out.");
    [_listeners removeObject: listener];
    return YES;
}



#pragma mark -
#pragma mark Scanning

- (BXMIDIInputListener *) _listenerForSource: (MIDIEndpointRef)source
{
    for (BXMIDIInputListener *listener in _listeners)
    {
        if ([listener source] == source) return listener;
    }
    return nil;
}

- (MIDIEndpointRef) _probableSourceForDestination: (MIDIEndpointRef)destination
{
    MIDIEntityRef entity = NULL;
    
    OSStatus errCode = MIDIEndpointGetEntity(destination, &entity);
    
    if (errCode == noErr)
    {
        MIDIEndpointRef source;
        
        //Check if this entity possesses a corresponding source for this destination.
        NSUInteger i, numSources = MIDIEntityGetNumberOfSources(entity);
        if (numSources > 0)
        {
            for (i = 0; i < numSources; i++)
            {
                source = MIDIEntityGetSource(entity, i);
                
                //Skip sources we're already listening to.
                if (![self _listenerForSource: source]) return source;
            }
        }
        
        //If the destination's own entity doesn't have any sources,
        //then fall back on the first unused source we can find in the system.
        else
        {
            numSources = MIDIGetNumberOfSources();
            
            for (i = 0; i < numSources; i++)
            {
                source = MIDIGetSource(i);
                
                //Skip sources we're already listening to.
                if (![self _listenerForSource: source]) return source;
            }
        }
    }
    
    //If we got this far, we couldn't find any suitable source.
    return NULL;
}

- (void) _scanDestination: (MIDIEndpointRef)destination
{
    //Look for a source that matches this destination:
    //this is what we'll listen on for response messages.
    MIDIEndpointRef source = [self _probableSourceForDestination: destination];
    
    if (source)
    {
        //Construct the MIDI message we want to send to this destination
        NSData *request = [[self class] _MT32IdentityRequest];
        
        UInt8 buffer[sizeof(MIDIPacketList)];
        MIDIPacketList *packets = (MIDIPacketList *)buffer;
        MIDIPacket *currentPacket = MIDIPacketListInit(packets);
        
        MIDIPacketListAdd(packets, sizeof(buffer), currentPacket, (MIDITimeStamp)0, [request length], (const UInt8 *)[request bytes]);

        OSStatus errCode = MIDISend(_outputPort, destination, packets);
        
        //If the message was sent out successfully, create a new listener to track the replies
        //from this destination's corresponding source.
        if (errCode == noErr)
        {
            BXMIDIInputListener *listener = [[BXMIDIInputListener alloc] initWithDelegate: self];
            [listener listenToSource: source onPort: _inputPort contextInfo: destination];
            
            [_listeners addObject: listener];
            [listener release];
        }
    }
}

- (void) _scanAvailableDestinations
{
    NSLog(@"Number of destinations: %lu sources: %lu", MIDIGetNumberOfDestinations(), MIDIGetNumberOfSources());
    NSUInteger i, numDestinations = MIDIGetNumberOfDestinations();
    for (i = 0; i < numDestinations; i++)
    {
        NSLog(@"Scanning MIDI destination at index %i", i);
        [self _scanDestination: MIDIGetDestination(i)];
    }
}

@end


@interface BXMIDIInputListener ()

- (void) _timeout;
- (void) _cancelTimeout;
- (void) _restartTimeout;
- (void) _addPacketData: (NSData *)data;

@end

@implementation BXMIDIInputListener
@synthesize port = _port;
@synthesize source = _source;
@synthesize contextInfo = _contextInfo;
@synthesize timeout = _timeout;
@synthesize delegate = _delegate;
@synthesize receivedData = _receivedData;


#pragma mark -
#pragma mark Class helpers

void _didReceiveMIDIInput(const MIDIPacketList *packets, void *portContext, void *connectionContext)
{
    [(BXMIDIInputListener *)connectionContext receivePackets: packets];
}

+ (MIDIPortRef) createListeningPortForClient: (MIDIClientRef)client
                                    withName: (NSString *)portName
                                       error: (NSError **)outError
{
    MIDIPortRef port;
    if (!portName) portName = @"MIDI In for Boxer MIDI Listener";
    OSStatus errCode = MIDIInputPortCreate(client, (CFStringRef)portName, _didReceiveMIDIInput, NULL, &port);
    
    if (errCode == noErr) return port;
    else
    {
        if (outError) *outError = [NSError errorWithDomain: NSOSStatusErrorDomain
                                                      code: errCode
                                                  userInfo: nil];
        return NULL;
    }
}


#pragma mark -
#pragma mark Initialization and deallocation

- (id) init
{
    if ((self = [super init]))
    {
        _receivedData = [[NSMutableData alloc] initWithLength: 0];
        [self setTimeout: BXMIDIInputListenerDefaultTimeout];
    }
    return self;
}

- (id) initWithDelegate: (id <BXMIDIInputListenerDelegate>)delegate
{
    if ((self = [self init]))
    {
        [self setDelegate: delegate];
    }
    return self;
}

- (void) dealloc
{
    [self stopListening];
    [_receivedData release], _receivedData = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark Listening and receiving data

- (void) listenToSource: (MIDIEndpointRef)source
                 onPort: (MIDIPortRef)port
            contextInfo: (void *)contextInfo
{
    NSAssert(![self isListening], @"Listener is already listening.");
    
    OSStatus errCode = MIDIPortConnectSource(port, source, self);
    if (errCode == noErr)
    {
        _port = port;
        _source = source;
        _contextInfo = contextInfo;
        
        //Record the thread on which this was called: this is the thread
        //on which we'll send delegate callbacks.
        _notificationThread = [NSThread currentThread];
        
        //Schedule the timeout
        [self _restartTimeout];
    }
}

- (void) stopListening
{
    if ([self isListening])
    {
        [self _cancelTimeout];
        MIDIPortDisconnectSource(_port, _source);
    }
    _notificationThread = nil;
    _port = nil;
    _source = nil;
}


- (void) receivePackets: (const MIDIPacketList *)packets
{
    NSMutableData *packetData = [[NSMutableData alloc] initWithLength: 0];
    
    const MIDIPacket *packet = &packets->packet[0];
    NSUInteger i;
    for (i = 0; i < packets->numPackets; ++i) {
        [packetData appendBytes: packet->data length: packet->length];
        packet = MIDIPacketNext(packet);
    }
    
    [self _addPacketData: packetData];
    
    [packetData release];
}

- (BOOL) isListening
{
    return _port != nil;
}

- (void) setTimeout: (NSTimeInterval)timeout
{
    _timeout = timeout;
    //Restart the timer whenever the timeout changes, as long as we're listening.
    if ([self isListening]) [self _restartTimeout];
}


#pragma mark -
#pragma mark Private methods

- (void) _addPacketData: (NSData *)data
{
    //To avoid gruesome threading issues, ensure we only add new data and
    //send notifications about it on the thread from which we were told to 
    //start listening.
    if ([NSThread currentThread] != _notificationThread)
    {
        [self performSelector: _cmd
                     onThread: _notificationThread
                   withObject: data
                waitUntilDone: NO];
        return;
    }
    
    //Make sure we're still listening. If we've been cancelled in between receiving
    //the original packet and getting around to recording it, then treat the packet
    //as though it never arrived.
    if ([self isListening])
    {
        [_receivedData appendData: data];
        [self _restartTimeout];
        
        if ([[self delegate] respondsToSelector: @selector(MIDIInputListener:receivedData:)])
        {
            [[self delegate] MIDIInputListener: self receivedData: data];
        }
    }
}

- (void) _timeout
{
    //Only send a notification if we're actually in the middle of listening.
    if ([self isListening])
    {
        BOOL stop = YES;
        
        if ([[self delegate] respondsToSelector: @selector(MIDIInputListenerShouldStopListeningAfterTimeout:)])
        {
            stop = [[self delegate] MIDIInputListenerShouldStopListeningAfterTimeout: self];
        }
        if (stop) [self stopListening];
    }
}

- (void) _cancelTimeout
{
    [NSObject cancelPreviousPerformRequestsWithTarget: self
                                             selector: @selector(_timeout)
                                               object: nil];    
}

- (void) _restartTimeout
{
    [self _cancelTimeout];
    if ([self timeout] > 0 && [self isListening])
        [self performSelector: @selector(_timeout)
                   withObject: nil
                   afterDelay: [self timeout]];
}

@end