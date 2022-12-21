/**
 * Created by ShiqiSun on 11/25/2021.
 */

import {api, LightningElement, wire} from 'lwc';
import getAccessories from "@salesforce/apex/PricingUtils.getAccessories";

export default class Accessorycreation extends LightningElement {
    @api accessory = {};

    @api relatedAssetPicklist = [];
    accessoryPicklist = [];

    accessoryPicklistValue = '';

    isAccessoryPicklistActive = true;

    headingRelatedAsset = '';
    headingAccessoryName = '';

    loading;

    programId;
    assetMake;
    assetType;
    assetModel;
    assetNum;

    callbackOnlyOnce = false;

    /*@wire(getAccessories, {programId: this.programId, make: this.assetMake})
    wiredGetAccessories({error, data}) {
        if (data) {
            let parsedResult = JSON.parse(data);

            console.log(parsedResult);

            this.accessoryPicklist = [];

            parsedResult.forEach(element => {

                this.accessoryPicklist.push({label: element.modelName, value: element.modelId});

            });
        } else {
            if (this.accessory) {
                console.log(JSON.stringify(error));
                console.log('Failure to get accessory data.');
            }
        }
    }*/

    //HANDLERS
    handleAddAccessory(event) {
        const accEvent = new CustomEvent("createaccessory");
        this.dispatchEvent(accEvent);
    }

    handleDeleteAccessory(event) {
        const accEvent = new CustomEvent("deleteaccessory", {
            detail: this.accessory.accNo
        });
        this.dispatchEvent(accEvent);
    }
    handleChange(event) {

         
        this.handleChangeSalesPrice(event);
         
        let tempAcc = JSON.parse(JSON.stringify(this.accessory));
        tempAcc[event.target.name] = event.target.value;
        const accEvent = new CustomEvent("updateaccessory", {
            detail: tempAcc
        })

        this.dispatchEvent(accEvent);
    }
    formatCurrencyForInput(event) {
        if (event.target.value.length !== 0) {
            this.template.querySelector(`[data-id="${event.target.name}"]`).value = '$' + this.formatCurrency(event.target.value);
        }
    }
    formatCurrency(str) {
        let result = this.removeInvalidPriceCharacters(str).split('.');
        let returnValue = '';
        let currentStep = 0;
        for (let i = result[0].length - 1; i >= 0; i--) {
            returnValue = result[0][i] + returnValue;
            currentStep++;
            if ((currentStep === 3) && (i !== 0)) {
                returnValue = ',' + returnValue;
                currentStep = 0;
            }
        }
        if ((result.length > 1) && (result[1].length !== 0)) {
            if (result[1].length === 1) {
                returnValue = returnValue + '.' + result[1];
            } else {
                returnValue = returnValue + '.' + result[1].substring(0, 2);
            }
        }
        return returnValue;
    }
    removeInvalidPriceCharacters(str) {
        let returnStr = '';
        for (let i = 0; i < str.length; i++) {
            if ((str[i] >= '0') && (str[i] <= '9')) {
                returnStr += str[i];
            } else if (str[i] === '.') {
                returnStr += '.';
            }
        }
        return returnStr;
    }
    handleChangeSalesPrice(event) {

        console.log('in here');
        let tempAcc = JSON.parse(JSON.stringify(this.accessory));
        let trimmedPrice = this.removeInvalidPriceCharacters(event.target.value.toString()); 
        trimmedPrice = trimmedPrice.split('.');
        if (trimmedPrice.length === 0) {
            trimmedPrice = 0;
        } else if (trimmedPrice.length === 1) {
            trimmedPrice = parseInt(trimmedPrice[0]);
            //Fix for Bug - Accessory not adding to Asset - Geetha
            //if (trimmedPrice[0].length === 0) {
            if (String(trimmedPrice).length === 0) {
                trimmedPrice = 0;
               
            }
           
        } else {
            if (trimmedPrice[1].length > 1) {
                trimmedPrice = trimmedPrice[0] + '.' + trimmedPrice[1].substring(0, 2);
            } else if (trimmedPrice[1].length === 1) {
                trimmedPrice = trimmedPrice[0] + '.' + trimmedPrice[1];
                
            } else {
                trimmedPrice = trimmedPrice[0] + '.';
            }
        }
      
        tempAcc[event.target.name] = trimmedPrice.toString();
        const accEvent = new CustomEvent("updateaccessory", {
            detail: tempAcc
        })

        this.dispatchEvent(accEvent);
    }
    handleAccessoryChange(event) {
        this.headingAccessoryName = event.target.options.find(opt => opt.value === event.detail.value).label;
        let tempAcc = JSON.parse(JSON.stringify(this.accessory));
        tempAcc[event.target.name] = event.target.value;
        tempAcc.model = this.headingAccessoryName;
        tempAcc.modelId = event.detail.value;
        tempAcc.accessoryHeading = 'Accessory ' + (tempAcc.accNo + 1) + ' | Asset ' + (parseInt(this.assetNum) + 1) + ' | ' + this.headingAccessoryName;
        const accEvent = new CustomEvent("updateaccessory", {
            detail: tempAcc
        })

        this.dispatchEvent(accEvent);
    }
    handleRelatedAssetChange(event) {
        this.loading = true;
        this.headingRelatedAsset = event.target.options.find(opt => opt.value === event.detail.value).label;
        if (this.headingRelatedAsset) {
            this.isAccessoryPicklistActive = false;
        } else {
            this.isAccessoryPicklistActive = true;
            this.accessory.accessoryPicklistValue = '';
        }
        let tokens = event.target.value.split('!@#$%^&*(');
        this.programId = tokens[0];
        this.assetMake = tokens[1];
        this.assetType = tokens[2];
        this.assetModel = tokens[3];
        this.assetNum = tokens[4];
        let modelLabel = tokens[6];
        if ((typeof this.programId !== 'undefined') && (typeof this.assetMake !== 'undefined')) {
            console.log('ProgramId');
            console.log(tokens[0]);
            console.log('Make');
            console.log(tokens[1]);
            getAccessories({  programId: this.programId, make: this.assetMake})
                .then(result => {
                    let parsedResult = JSON.parse(result);

                    console.log(parsedResult);

                    this.accessoryPicklist = [];

                    parsedResult.forEach(element => {

                        this.accessoryPicklist.push({label: element.modelName, value: element.modelId});

                    });
                    this.loading = false;
                })
                .catch(error => {
                    console.log(JSON.parse(JSON.stringify(error)));
                    console.log('Failure to get accessory data.');
                    this.loading = false;
                });
        } else {
            this.loading = false;
        }
        let tempAcc = JSON.parse(JSON.stringify(this.accessory));
        tempAcc.relatedAsset = this.assetNum;
        tempAcc.accessoryHeading = 'Accessory ' + (tempAcc.accNo + 1) + ' | Asset ' + (parseInt(this.assetNum) + 1);
        const accEvent = new CustomEvent("updateaccessory", {
            detail: tempAcc
        })

        this.dispatchEvent(accEvent); 
    }

    connectedCallback() {
        if (this.callbackOnlyOnce) {
            return;
        }
        this.callbackOnlyOnce = true;
        if (!this.accessory.relatedAssetTotal) {
            return;
        }
        let tokens = this.accessory.relatedAssetTotal.split('!@#$%^&*(');
        this.programId = tokens[0];
        this.assetMake = tokens[1];
        this.assetType = tokens[2];
        this.assetModel = tokens[3];
        this.assetNum = tokens[4];
        let modelLabel = tokens[6];
        if ((typeof this.programId !== 'undefined') && (typeof this.assetMake !== 'undefined')) {
            console.log('ProgramId');
            console.log(tokens[0]);
            console.log('Make');
            console.log(tokens[1]);
            getAccessories({  programId: this.programId, make: this.assetMake})
                .then(result => {
                    let parsedResult = JSON.parse(result);

                    console.log(parsedResult);

                    this.accessoryPicklist = [];

                    parsedResult.forEach(element => {

                        this.accessoryPicklist.push({label: element.modelName, value: element.modelId});

                    });
                    this.loading = false;
                    this.isAccessoryPicklistActive = false;
                    /*let headingWithAccessory = this.accessory.accessoryHeading.split('|');
                    this.accessory.accessoryHeading = headingWithAccessory[0] + '|' + headingWithAccessory[1] + '|' + this.accessoryPicklist.find(val => val.value === this.accessory.accessoryPicklistValue).label;
                    let tempAcc = JSON.parse(JSON.stringify(this.accessory));
                    const accEvent = new CustomEvent("updateaccessory", {
                        detail: tempAcc
                    });
                    this.dispatchEvent(accEvent);*/
                })
                .catch(error => {
                    console.log(JSON.parse(JSON.stringify(error)));
                    console.log('Failure to get accessory data.');
                    this.loading = false;
                });
        }
    }
}