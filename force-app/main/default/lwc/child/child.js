import UserPreferencesEnableAutoSubForFeeds from '@salesforce/schema/User.UserPreferencesEnableAutoSubForFeeds';
import { LightningElement, api  } from 'lwc';

export default class Child extends LightningElement {
    className = "greenBar";
    connectedCallback(){
        this.register();

    }

    register(){
        console.log('event registered');
         
    }
    @api childMethod(param){
        console.log('called child');
    }
}