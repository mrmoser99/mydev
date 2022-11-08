/**
 * CometD is a scalable HTTP-based event routing bus that uses an AJAX push technology pattern known as Comet. 
 * It implements the Bayeux protocol. Long polling, also called Comet programming, allows emulation of an information 
 * push from a server to a client. Similar to a normal poll, the client connects and requests information from the server. 
 * However, instead of sending an empty response if information isn't available, the server holds the request and waits 
 * until information is available (an event occurs).
 */
import { LightningElement, api, track, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import cometd from '@salesforce/resourceUrl/cometd';
import getSessionId from '@salesforce/apex/GenericUtilityClass.getSessionId';

export default class CometD extends LightningElement {
    @api channel;
    libInitialized = false;
    @track sessionId;
    @track error;

    // get session id and initialize CometD 
    @wire(getSessionId)
    wiredSessionId({ error, data }) {
        if (data) {
            this.sessionId = data;
            this.error = undefined;
            loadScript(this, cometd)
            .then(() => {
                this.initializeCometD();
            });
        } else if (error) {
            this.error = error;
            this.sessionId = undefined;
        }
    }

    sayHello(msg){
        console.log('cometd says: ' + msg);
    }
    // initialize CometD 
    initializeCometD() {
        if (this.libInitialized) {
            return;
        }
        this.libInitialized = true;
        var lwcThisContext = this;
        var cometdlib = new window.org.cometd.CometD();
        cometdlib.configure({
            url: window.location.protocol + '//' + window.location.hostname + '/cometd/51.0/',
            requestHeaders: { Authorization: 'OAuth ' + this.sessionId},
            appendMessageTypeToURL : false,
            logLevel: 'debug'
        });
        cometdlib.websocketEnabled = false;
        cometdlib.handshake(function(status) {
            if (status.successful) {
                cometdlib.subscribe(lwcThisContext.channel, function(message){
                    const selectedEvent = new CustomEvent('message', { detail: message });
                    lwcThisContext.dispatchEvent(selectedEvent);
                });
                
            } else {
                console.error('Error in handshaking: ' + JSON.stringify(status));
            }
        });
    }
}