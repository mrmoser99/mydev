import { LightningElement, api, wire, track } from 'lwc';
import { constants } from 'c/ldsUtils';

export default class ESignDocuments extends LightningElement {
    @api quoteId;
    @api documents = [];
    @api loaded = false;

    labels = constants;
}