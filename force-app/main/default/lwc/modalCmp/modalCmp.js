import { LightningElement, api } from 'lwc';

export default class ModalCmp extends LightningElement {
    @api title;
    @api subtitle;
}