import { LightningElement,api} from 'lwc';

export default class LightningLoader extends LightningElement {

    @api spinnerText = '';
    @api size = "medium";
    @api variant = "brand";

    get helpText(){
       return this.spinnerText ? this.spinnerText : 'Loading';
    }
}