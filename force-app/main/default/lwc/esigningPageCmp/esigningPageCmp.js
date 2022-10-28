import { LightningElement } from 'lwc';
import { getUrlParamValue } from 'c/ldsUtils';

export default class EsigningPageCmp extends LightningElement {
    esigningRequest = '';
    signurl = 'signUrl';
    isNotificationStatic = true;

    connectedCallback(){
        this.esigningRequest = decodeURIComponent(getUrlParamValue(window.location.href, this.signurl));
    }
   
}