/**
 * Created by ShiqiSun on 11/18/2021.
 */

/*
 Change Log:  

 11/11/2022 - MRM - Added a return in the wired get makes to return if null is sent in....
*/

import {LightningElement, wire, api, track} from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//apex
import getMakes from "@salesforce/apex/PricingUtils.getMakes";
import getAssetTypes from "@salesforce/apex/PricingUtils.getAssetTypes";
import getModels from "@salesforce/apex/PricingUtils.getModels";
import getAsset from "@salesforce/apex/PricingUtils.getAsset";
import getSubsidies from '@salesforce/apex/PricingUtils.getSubsidies';
import StayInTouchSignature from '@salesforce/schema/User.StayInTouchSignature';

export default class assetcreation extends LightningElement {
    @api asset = {};
    @api programId;
    /*@api
    get programId() {
        return this.programIdChange;
    }
    set programId(value) {
        this.programIdChange = value;
        if (!(typeof this.programIdChange !== 'undefined') && (this.programIdChange.length !== 0)) {
            this.getMakesNotWired(this.programIdChange);
        }
    }*/

    @track loading = false;

    //programIdChange;

    //attributes for currently selected values;
    mastType;
    assetOperating;
    annualHours;
    batteryIncluded;
    numberOfUnits;
    unitSalesPrice;
    subsidy;
    subsidyName;
    make = {};
    assetType = {};
    model = {};

     

   
    @api  
    quoteObject = {
        deleteAssets: [],
        isEdit: false,
        isClone: false,
        assetTypeQuote: 'New',
        financeType:'BO',
        paymentFrequency: 'Monthly',
        advPayments: '0',
        program: null,
        programId: null,
        location: null,
        locationId: null,
        nickname: null,
        financeTerm: null,
        option: null
    };
    //Lists
    makePicklist = [];
    assetTypePicklist = [];
    modelPicklist = [];
    mastList = [];
    assetOperatingList = [];
    annualHoursList = [];
    batteryIncludedList = [];
    @api subsidyList = [];

    connectedCallbackLoopPrevention = true;

    //Controls for disable
    @api
    get isMakeDisabled() {
        
        return this.programId === '';
    }
    @api
    get isAssetTypeDisabled() {
        return typeof this.asset.make === 'undefined';
    }
    @api
    get isModelDisabled() {
        return typeof this.asset.assetType === 'undefined';
    }
    @api
    get isRestDisabled() {
        return typeof this.asset.model === 'undefined';
    }
    @api
    get isBatteryIncludedDisabled() {
        return this.batteryIncludedList.length < 2;
    }
    @api
    get isSubsidyDisabled() {
        return this.subsidyList.length < 2;
    }
    /*@api
    get isSubsidyDisabled() {
        return (typeof this.quoteObject.programId === 'undefined') ||
            (typeof this.quoteObject.financeType === 'undefined') ||
            (typeof this.quoteObject.financeTerm === 'undefined') ||
            (typeof this.asset.make === 'undefined') ||
            (typeof this.quoteObject.paymentFrequency === 'undefined') ||
            (typeof this.asset.model === 'undefined');
    }*/

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
        this.dispatchEvent(event);
    }

     connectedCallback() {
        //console.log(' in asset creation - program is :' + this.programId + '-' 
        //+ JSON.stringify(this.quoteObject) );
        
     }

    /***********************************************************************************************************
     * getMakes
     ************************************************************************************************************/
    @wire(getMakes, {programId: '$programId'})
    wiredgetMakes({error, data}) {
         
        if (this.programId == undefined){
            //console.log('dont do anything on null');
            return;
        }
         
            
        //console.log('he hit here with program id: ' + this.programId);
        //console.log('this.asset = ' +JSON.stringify(this.asset) + JSON.stringify(this.quoteObject));
        this.loading = true;


        this.data = data;
        let mlist = [];

        if (this.data) {

            //Code to fetch subsidy on edit - Geetha :
            let labelValue = (this.asset.subsidy) == "No" ? 'No' : 'Yes'; 
            this.subsidyList = [
                {label: labelValue, value: this.asset.subsidy}]


            data = JSON.parse(data);

            data.forEach(function (element) {
                //console.log(element);

                mlist.push({label: element.makeName, value: element.makeId});

            });
            //console.log(this.asset.make + 'this is the make');
            if(typeof this.asset.make !== 'undefined' && typeof this.programId !== 'undefined'){
                this.make.label = this.asset.make;
                this.make.value = this.asset.makeId;
                this.getAssetTypes(this.programId, this.make.label);
                this.makePicklist = mlist;
                return;
            }
            this.loading = false;

        } else if (error) {

            this.loading = false;
            if (this.programId) {
                this.showToast('Something went wrong trying to get makes', 'error.body.message', 'error');
            }
            return;

        }



        this.makePicklist = mlist;

        this.isLoading = false;
    }

    /*getMakesNotWired(programId) {
        this.loading = true;
        let mlist = [];
        getMakes({'programId': programId})
            .then(result => {
                data = JSON.parse(result);

                data.forEach(function (element) {
                    //console.log(element);

                    mlist.push({label: element.makeName, value: element.makeId});

                });
                //console.log(this.asset.make + 'this is the make');
                if(typeof this.asset.make !== 'undefined' && typeof this.programIdChange !== 'undefined'){
                    this.make.label = this.asset.make;
                    this.make.value = this.asset.makeId;
                    this.getAssetTypes(this.programIdChange, this.make.label);
                }
                this.loading = false;
            })
            .catch(error => {
                //console.log(JSON.stringify(error));
                this.showToast('getMakes error', error, 'error');
                this.loading = false;
            });
        this.makePicklist = mlist;
    }*/

    //API calls to get picklist values
    getAssetTypes(programId, make) {
        //console.log('got in here');
        getAssetTypes({programId: programId, triggerAssetTypes: make})
            .then(results => {


                let res = JSON.parse(results);
                let aList = [];

                res.forEach(function (element) {


                    aList.push({label: element.assetTypeName, value: element.assetTypeId});

                });
                if(typeof this.asset.assetType !== 'undefined'){
                    this.assetType.value = this.asset.assetTypeId;
                    this.assetType.label = this.asset.assetType;
                    this.getModels();
                    this.assetTypePicklist = aList;
                    return;
                }
                this.assetTypePicklist = aList;
                this.loading = false;
            })
            .catch(error => {
                this.showToast('Error getting Asset Types for an Asset', 'There are no asset types being returned.', 'warning'); 
                //console.log(JSON.parse(JSON.stringify(error)));
                this.loading = false;
                this.showToast('Something went wrong', 'error', 'error');

            });

    }



    getModels() {

        getModels({programId: this.programId, make: this.make.value, assetType: this.assetType.value})
            .then(results => {


                let res = JSON.parse(results);

                //console.log('getModels');
                //console.log(res);

                let mlist = [];

                res.forEach(function (element) {
                    mlist.push({label: element.modelName, value: element.modelId});
                });

                this.modelPicklist = mlist;
                if(typeof this.asset.modelId !== 'undefined'){
                    this.getOtherInformation(this.asset.modelId);
                    return;
                }
                this.loading = false;
            }).catch(error => {
                this.showToast('Error getting models for an Asset', 'No Models available for this Class.', 'warning');
                //console.log(error);
                let tempAsset = JSON.parse(JSON.stringify(this.asset));
                tempAsset.assetType = undefined;
                tempAsset.assetTypeId = undefined;
                this.assetType.value = undefined;
                this.assetType.label = undefined;
                const assetEvent = new CustomEvent("updateasset", {
                    detail: tempAsset
                })

                this.dispatchEvent(assetEvent);

                this.loading = false; 
        });
    }

    getOtherInformation(modelId) {

        let loadsToGo = 1;

        /*if ((typeof this.quoteObject.programId === 'undefined') ||
            (typeof this.quoteObject.financeType === 'undefined') ||
            (typeof this.quoteObject.financeTerm === 'undefined') ||
            (typeof this.asset.make === 'undefined') ||
            (typeof this.quoteObject.paymentFrequency === 'undefined') ||
            (typeof this.asset.model === 'undefined') ||
            (typeof this.asset.unitSalesPrice === 'undefined')) {
            loadsToGo--;
        }*/

        getAsset({  programId: this.programId, assetId: modelId})
            .then(result => {

                this.loading=true;

                //console.log(' result is: ' + JSON.parse(result));

                this.data = result;
                let elist = [];
                let hlist = [];
                let mlist = [];
                let blist = [];

                if (this.data) {

                    let obj = JSON.parse(this.data);


                    var ob =  obj["data"]["finance"]["residualValue"]["adjustments"]["industrialBattery"];
                    if (ob != null){
                        for (let i = 0; i < ob.length; i++) {

                            let lab = obj["data"]["finance"]["residualValue"]["adjustments"]["industrialBattery"][i];
                            let val = obj["data"]["finance"]["residualValue"]["adjustments"]["industrialBattery"][i];

                            blist.push({label: lab, value: val});
                        }
                    }

                    var om =  obj["data"]["finance"]["residualValue"]["adjustments"]["mastType"];
                    if (om != null){
                        for (let i = 0; i < om.length; i++) {

                            let lab = obj["data"]["finance"]["residualValue"]["adjustments"]["mastType"][i];
                            let val =obj["data"]["finance"]["residualValue"]["adjustments"]["mastType"][i];


                            mlist.push({label: lab, value: val});
                        }
                    }

                    var oe = obj["data"]["finance"]["residualValue"]["adjustments"]["operatingEnvironment"];


                    if (oe != null){
                        for (let i = 0; i < oe.length; i++) {

                            let lab = obj["data"]["finance"]["residualValue"]["adjustments"]["operatingEnvironment"][i];
                            let val= obj["data"]["finance"]["residualValue"]["adjustments"]["operatingEnvironment"][i];


                            elist.push({label: lab, value: val});
                        }
                    }

                    var oh = obj["data"]["finance"]["residualValue"]["adjustments"]["operatingHoursPerYear"];

                    if (oh != null){
                        for (let i = 0; i < oh.length; i++) {

                            let lab = obj["data"]["finance"]["residualValue"]["adjustments"]["operatingHoursPerYear"][i];
                            let val= obj["data"]["finance"]["residualValue"]["adjustments"]["operatingHoursPerYear"][i];


                            hlist.push({label: lab, value: val});
                        }
                    }

                    let tempAsset = JSON.parse(JSON.stringify(this.asset));
                    tempAsset.type = obj['data']['catalog']['identifiers']['structure']['type'];
                    tempAsset.msrp = String(obj['data']['catalog']['listPrice']);
                    if (blist.length !== 0) {
                        if (blist.length === 1) {
                            tempAsset.batteryIncluded = blist[0].value;
                        } else if (blist.length === 2) {
                            tempAsset.batteryIncluded = 'Yes';
                        }
                    }
                    const assetEvent = new CustomEvent("updateasset", {
                        detail: tempAsset
                    })

                    this.dispatchEvent(assetEvent);

                }
                this.assetOperatingList = elist;
                this.annualHoursList = hlist;
                //console.log(this.annualHoursList);
                this.mastList = mlist;
                this.batteryIncludedList = blist;
                loadsToGo--;
                if (loadsToGo === 0) {
                    this.loading = false;
                }
                if ((typeof this.quoteObject.programId !== 'undefined') &&
                    (typeof this.quoteObject.financeType !== 'undefined') &&
                    (typeof this.quoteObject.financeTerm !== 'undefined') &&
                    (typeof this.asset.make !== 'undefined') &&
                    (typeof this.quoteObject.paymentFrequency !== 'undefined') &&
                    (typeof this.asset.unitSalesPrice !== 'undefined') &&
                    (typeof this.asset.numberOfUnits !== 'undefined') &&
                    (typeof this.quoteObject.rateTypeId !== 'undefined')) {
                    this.callSubsidies({});
                }
        }).catch(error=>{
            this.showToast('Error getting other info for an Asset', error.body.message, 'error');
            //console.log(JSON.parse(JSON.stringify(error)));
            ////console.log(error);
            loadsToGo--;
            if (loadsToGo === 0) {
                this.loading = false;
            }
        });

        /*if ((typeof this.quoteObject.programId === 'undefined') ||
            (typeof this.quoteObject.financeType === 'undefined') ||
            (typeof this.quoteObject.financeTerm === 'undefined') ||
            (typeof this.asset.make === 'undefined') ||
            (typeof this.quoteObject.paymentFrequency === 'undefined') ||
            (typeof this.asset.model === 'undefined') ||
            (typeof this.asset.unitSalesPrice === 'undefined')) {
            return;
        }

        getSubsidies({ programId: this.quoteObject.programId, productId: this.quoteObject.financeType, numberOfMonths: this.quoteObject.financeTerm,
            make : this.makePicklist.find(opt => opt.value === this.asset.make).label,
            paymentFrequency: this.quoteObject.paymentFrequency, financeAmount : this.asset.unitSalesPrice,
            assetCondition: 'new', paymentTiming : 'in-arrears'})
            .then(result => {
                //console.log('Apex has finished with getSubsidies');
                let data = JSON.parse(result);
                //console.log(JSON.parse(JSON.stringify(data)));
                //console.log('there is data' + data);
                let sList = [];

                data.forEach(function(element){

                    sList.push({label: element.name, value: element.id});

                });

                this.subsidyList = sList;
                loadsToGo--;
                if (loadsToGo === 0) {
                    this.loading = false;
                }


            })
            .catch(error => {
                //console.log(JSON.parse(JSON.stringify(error)));
                loadsToGo--;
                if (loadsToGo === 0) {
                    this.loading = false;
                }
                this.showToast('Something went wrong', error.body.message, 'error');
            });*/
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

    callSubsidies(event) {
        //console.log('in call sub' + JSON.stringify(this.quoteObject));
        if (event.target.value.length !== 0) {
            this.template.querySelector(`[data-id="${event.target.name}"]`).value = '$' + this.formatCurrency(event.target.value);
        }
        if ((typeof this.quoteObject.programId === 'undefined') ||
            (typeof this.quoteObject.financeType === 'undefined') ||
            (typeof this.quoteObject.financeTerm === 'undefined') ||
            (typeof this.asset.make === 'undefined') ||
            (typeof this.quoteObject.paymentFrequency === 'undefined') ||
            (typeof this.asset.unitSalesPrice === 'undefined') ||
            (typeof this.asset.numberOfUnits === 'undefined') ||
            (typeof this.quoteObject.rateTypeId === 'undefined')) {
            let missingDataNames = [];
            if (typeof this.quoteObject.programId === 'undefined') {
                missingDataNames.push('Program');
            }
            if (typeof this.quoteObject.rateTypeId === 'undefined') {
                missingDataNames.push('Rate Type Id');
            }
            if (typeof this.quoteObject.financeType === 'undefined') {
                missingDataNames.push('Lease Type');
            }
            if (typeof this.quoteObject.financeTerm === 'undefined') {
                missingDataNames.push('Finance Term');
            }
            if (typeof this.asset.make === 'undefined') {
                missingDataNames.push('Make');
            }
            if (typeof this.quoteObject.paymentFrequency === 'undefined') {
                missingDataNames.push('Payment Frequency');
            }
            if (typeof this.asset.unitSalesPrice === 'undefined') {
                missingDataNames.push('Unit Sales Price');
            }
            if (typeof this.asset.numberOfUnits === 'undefined') {
                missingDataNames.push('Number of Units');
            }
            this.showToast('Missing data for subsidies', missingDataNames.join(', '), 'error');
            return;
        }

        //console.log('here 2');

        this.loading = true;

        //console.log(this.quoteObject.programId);
        //console.log(this.quoteObject.rateTypeId);
        //console.log(this.quoteObject.financeTerm);
        //console.log(this.makePicklist.find(opt => opt.value === this.asset.makeId).label);
        //console.log(this.quoteObject.paymentFrequency);
        //console.log(this.asset.numberOfUnits * this.asset.unitSalesPrice);

        let financeTypeTranslated = this.quoteObject.financeType;

        if (financeTypeTranslated === 'Fair Market Value ( FMV )') {
            financeTypeTranslated = 'fair-market-value';
        } else if (financeTypeTranslated === 'BO') {
            financeTypeTranslated = 'dollar-out';
        }
        //console.log('abc' + this.quoteObject.assetTypeQuote);
     
        getSubsidies({ programId: this.quoteObject.programId, productId: this.quoteObject.rateTypeId,
            numberOfMonths: this.quoteObject.financeTerm, make : this.makePicklist.find(opt => opt.value === this.asset.makeId).label,
            paymentFrequency: this.quoteObject.paymentFrequency.toLowerCase(), financeAmount : this.asset.numberOfUnits * this.asset.unitSalesPrice,
            assetCondition: this.quoteObject.assetTypeQuote, paymentTiming : 'in-arrears', financeType : financeTypeTranslated}) 
            .then(result => {
                //console.log('Apex has finished with getSubsidies');
                ////console.log(result);
                let data = JSON.parse(result);
                //console.log(JSON.parse(JSON.stringify(data)));
                let subsidyFound = 'false';
            
                if (data.data.subsidies.manufacturer[0].interest.nominalRate.percentages.length > 0)
                    subsidyFound = 'true';
                
                //console.log('subsidy: ' + subsidyFound);


                if (subsidyFound === 'true') { //remember to add subsidy name (this.subsidyName)
                    this.subsidyList = [
                        {label: 'Yes', value: data.data.subsidies.manufacturer[0].id},
                        {label: 'No', value: ''}];
                    this.subsidyName = data.data.subsidies.manufacturer[0].name;
                    if (typeof this.asset.subsidy === 'undefined') {
                        let tempAsset = JSON.parse(JSON.stringify(this.asset));
                        tempAsset.subsidy = data.data.subsidies.manufacturer[0].id;
                        tempAsset.subsidyName = this.subsidyName;
                        const assetEvent = new CustomEvent("updateasset", {
                            detail: tempAsset
                        })

                        this.dispatchEvent(assetEvent);
                    } else if (this.asset.subsidy === 'No') {
                        let tempAsset = JSON.parse(JSON.stringify(this.asset));
                        tempAsset.subsidy = '';
                        tempAsset.subsidyName = '';
                        const assetEvent = new CustomEvent("updateasset", {
                            detail: tempAsset
                        })

                        this.dispatchEvent(assetEvent);
                    }
                } else {
                    this.subsidyList = [{label: 'No', value: ''}];
                    let tempAsset = JSON.parse(JSON.stringify(this.asset));
                    tempAsset.subsidy = '';
                    tempAsset.subsidyName = '';
                    const assetEvent = new CustomEvent("updateasset", {
                        detail: tempAsset
                    })

                    this.dispatchEvent(assetEvent);
                }

                this.loading = false;

            })
            .catch(error => {
                //console.log(JSON.parse(JSON.stringify(error)));
                this.loading = false;
                this.showToast('Something went wrong', 'error.body.message', 'error');
            });
    }

    //HANDLERS
    handleAddAsset(event) {
        const assetEvent = new CustomEvent("createasset");
        this.dispatchEvent(assetEvent);
    }

    handleDeleteAsset(event) {
        const assetEvent = new CustomEvent("deleteasset", {
            detail: this.asset.assetNo
        });
        this.dispatchEvent(assetEvent);
    }

    handleChange(event) {
        let tempAsset = JSON.parse(JSON.stringify(this.asset));
        tempAsset[event.target.name] = event.target.value;
        const assetEvent = new CustomEvent("updateasset", {
            detail: tempAsset
        })

        this.dispatchEvent(assetEvent);
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
        let dataIdVar = event.target.name;
        let tempAsset = JSON.parse(JSON.stringify(this.asset));
        let trimmedPrice = this.removeInvalidPriceCharacters(event.target.value.toString());
        trimmedPrice = trimmedPrice.split('.');
        if (trimmedPrice.length === 0) {
            trimmedPrice = 0;
        } else if (trimmedPrice.length === 1) {
            if (trimmedPrice[0].length !== 0) {
                trimmedPrice = parseInt(trimmedPrice[0]);
            } else {
                trimmedPrice = '';
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
        //console.log('TrimmedPrice::' + trimmedPrice);
        tempAsset[event.target.name] = trimmedPrice.toString();
        const assetEvent = new CustomEvent("updateasset", {
            detail: tempAsset
        })

        this.dispatchEvent(assetEvent);
    }

    handleChangeSubsidy(event) {
        let tempAsset = JSON.parse(JSON.stringify(this.asset));
        tempAsset[event.target.name] = event.target.value;
        if (event.target.value !== '') {
            tempAsset.subsidyName = this.subsidyName;
        } else {
            tempAsset.subsidyName = '';
        }
        const assetEvent = new CustomEvent("updateasset", {
            detail: tempAsset
        })

        this.dispatchEvent(assetEvent);
    }


    handleDependentChange(event) {
       
        this.loading = true;
        //this.asset.assetHeading = 'Asset Details - ' + event.target.options.find(opt => opt.value === event.detail.value).label;
        ////console.log('Made it past new changes');
        this[event.target.name].value = event.target.value;
        this[event.target.name].label = event.target.options.find(opt => opt.value === event.detail.value).label;
        let tempAsset = JSON.parse(JSON.stringify(this.asset));
        tempAsset[event.target.name] = event.target.options.find(opt => opt.value === event.detail.value).label;
        tempAsset[event.target.name + 'Id'] = event.target.value;
        let selectedMake = event.target.options.find(opt => opt.value === event.detail.value).label;
        if (selectedMake) {
            tempAsset.assetHeading = 'Asset ' + (tempAsset.assetNo + 1) + ' | ' + selectedMake;
        }
        tempAsset.assetType = undefined;
        tempAsset.assetTypeId = undefined;
        this.assetType = {};
        tempAsset.model = undefined;
        tempAsset.modelId = undefined;
        this.model = {};
        tempAsset.mastType = undefined;
        tempAsset.assetOperating = undefined;
        tempAsset.annualHours = undefined;
        tempAsset.batteryIncluded = undefined;
        tempAsset.numberOfUnits = undefined;
        tempAsset.unitSalesPrice = undefined;
        tempAsset.subsidy = undefined;
        tempAsset.subsidyName = undefined;
        this.batteryIncludedList = [];
        this.subsidyList = [];
        this.loading = true;
        this.getAssetTypes(this.programId, this.make.value);
        if(typeof tempAsset.assetType !== 'undefined') {
            this.getModels();
        }
        const assetEvent = new CustomEvent("updateasset", {
            detail: tempAsset
        })

        this.dispatchEvent(assetEvent);

    }

    handleDependentModelChange(event) {
        this.loading = true;
        this[event.target.name].value = event.target.value;
        this[event.target.name].label = event.target.options.find(opt => opt.value === event.detail.value).label;
        let tempAsset = JSON.parse(JSON.stringify(this.asset));
        tempAsset[event.target.name] = event.target.options.find(opt => opt.value === event.detail.value).label;
        tempAsset[event.target.name + 'Id'] = event.target.value;
        if (tempAsset.make) {
            tempAsset.assetHeading = 'Asset ' + (tempAsset.assetNo + 1) + ' | ' + tempAsset.make;
        }
        if (typeof tempAsset.model !== 'undefined') {
            tempAsset.assetHeading = tempAsset.assetHeading + ' ' + tempAsset.model;
        }
        tempAsset.model = undefined;
        tempAsset.modelId = undefined;
        this.model = {};
        tempAsset.mastType = undefined;
        tempAsset.assetOperating = undefined;
        tempAsset.annualHours = undefined;
        tempAsset.batteryIncluded = undefined;
        tempAsset.numberOfUnits = undefined;
        tempAsset.unitSalesPrice = undefined;
        tempAsset.subsidy = undefined;
        tempAsset.subsidyName = undefined;
        this.batteryIncludedList = [];
        this.subsidyList = [];
        this.loading = true;
        this.getModels();
        const assetEvent = new CustomEvent("updateasset", {
            detail: tempAsset
        })

        this.dispatchEvent(assetEvent);

    }

    handleDependentFieldsChange(event) { 
        this.loading = true;
        this[event.target.name].value = event.target.value;
        this[event.target.name].label = event.target.options.find(opt => opt.value === event.detail.value).label;
        let tempAsset = JSON.parse(JSON.stringify(this.asset));
        tempAsset[event.target.name] = event.target.options.find(opt => opt.value === event.detail.value).label;
        tempAsset[event.target.name + 'Id'] = event.target.value;
        let selectedModel = event.target.options.find(opt => opt.value === event.detail.value).label;
        if (selectedModel) {
            tempAsset.assetHeading = 'Asset ' + (tempAsset.assetNo + 1) + ' | ' + tempAsset.make + ' ' + selectedModel;
        }
        tempAsset.mastType = undefined;
        tempAsset.assetOperating = undefined;
        tempAsset.annualHours = undefined;
        tempAsset.batteryIncluded = undefined;
        tempAsset.numberOfUnits = undefined;
        tempAsset.unitSalesPrice = undefined;
        tempAsset.subsidy = undefined;
        tempAsset.subsidyName = undefined;
        this.subsidyList = [];
        this.loading = true;
        //console.log('got here');
        this.getOtherInformation(event.target.value);
        const assetEvent = new CustomEvent("updateasset", {
            detail: tempAsset
        })

        this.dispatchEvent(assetEvent);
    }

    //Geetha - new code for unitprice
    @api
    resetUnitPrice(){
        //console.log('resetUnitPrice now ' );
        this.template.querySelector('[data-id="unitSalesPrice"]').value = '';
        this.template.querySelector('[data-id="subsidy"]').value = undefined;
       // this.asset.subsidy = undefined;
    }

}