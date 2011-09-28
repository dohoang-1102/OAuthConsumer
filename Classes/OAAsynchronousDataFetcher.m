//
//  OAAsynchronousDataFetcher.m
//  OAuthConsumer
//
//  Created by Zsombor Szabó on 12/3/08.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "OAAsynchronousDataFetcher.h"

#import "OAServiceTicket.h"

@implementation OAAsynchronousDataFetcher {
    OAMutableURLRequest *request;
    NSHTTPURLResponse *response;
    NSURLConnection *connection;
    NSMutableData *responseData;
	OAFetchRequestHandler handler;
}

+ (id)asynchronousFetcherWithRequest:(OAMutableURLRequest *)aRequest resultHandler:(OAFetchRequestHandler)handler
{
	return [[self alloc] initWithRequest:aRequest resultHandler:handler];
}

- (id)initWithRequest:(OAMutableURLRequest *)aRequest resultHandler:(OAFetchRequestHandler)aHandler
{
	if ( !(self = [super init]) ) return nil;
	
	request = aRequest;
	handler = aHandler;

	return self;
}

- (void)start
{    
    [request prepare];
	
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
	if (connection)
	{
		responseData = [[NSMutableData alloc] init];
	}
	else
	{
        OAServiceTicket *ticket= [[OAServiceTicket alloc] initWithRequest:request
                                                                 response:nil
                                                               didSucceed:NO];
		handler(nil, ticket, nil);
	}
}

- (void)cancel
{
	if (connection)
	{
		[connection cancel];
		connection = nil;
	}
}

#pragma mark -
#pragma mark NSURLConnection methods

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSHTTPURLResponse *)aResponse
{
	response = aResponse;
	[responseData setLength:0];
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error
{
	OAServiceTicket *ticket= [[OAServiceTicket alloc] initWithRequest:request
															 response:response
														   didSucceed:NO];

	handler(nil, ticket, error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
	OAServiceTicket *ticket = [[OAServiceTicket alloc] initWithRequest:request
															  response:response
															didSucceed:[response statusCode] < 400];
    
    NSStringEncoding encoding = NSISOLatin1StringEncoding;
    NSString *contentType = [[[response allHeaderFields] objectForKey:@"Content-Type"] lowercaseString];
    if (contentType && [contentType rangeOfString:@"charset=utf-8"].location != NSNotFound) {
        encoding = NSUTF8StringEncoding;
    }
    NSString *responseString = [[NSString alloc] initWithData:responseData encoding:encoding];

    handler(responseString, ticket, nil);
}

@end
