/**
 * Created by ShiqiSun on 11/18/2021.
 */

import {LightningElement, wire, api, track} from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//apex
import getModels from "@salesforce/apex/AssetUtils.getModels";
import getAsset from "@salesforce/apex/AssetUtils.getAsset";

export default class AssetCreationBase extends LightningElement {
    @api asset = {};
    @api programId;

    @track loading = false;
    @track loadingAssetTypes = false;
    @track loadingModels = false;

    //attributes for currently selected values;
    mastType;
    assetOperating;
    annualHours;
    batteryIncluded;
    numberOfUnits;
    unitSalesPrice;
    subsidy;
    subsidyName;

    //Lists
    @api makePicklist = [];
    assetTypePicklist = [];
    modelPicklist = [];
    modelPicklistFiltered = [];
    mastList = [];
    assetOperatingList = [];
    annualHoursList = [];
    batteryIncludedList = [];
    subsidyList = [];

    connectedCallbackLoopPrevention = true;

    //Controls for disable
    @api
    get isMakeDisabled() {
        return (!this.programId || this.programId === '') ? true : false;
    }
    @api
    get isAssetTypeDisabled() {
        return (!this.makeId || this.makeId === '') ? true : false;
    }
    @api
    get isModelDisabled() {
        return (this.makeId && this.assetTypeId) ? false : true;
    }
    @api
    get isRestDisabled() {
        return (this.modelId) ? false : true;
    }
    @api
    get isBatteryIncludedDisabled() {
        return this.batteryIncludedList.length < 2;
    }
    @api
    get isSubsidyDisabled() {
        return this.subsidyList.length === 0;
    }

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
        console.log('this.connectedCallback is running');
        console.log(this.asset);
        console.log(JSON.stringify(this.asset));
        console.log(JSON.parse(JSON.stringify(this.asset)));
        // console.log(this.asset);
        console.log(this.asset.make);
        console.log(this.asset.model);
        console.log(this.makeId);
        console.log(this.modelId);
        console.log(this.assetTypeId);

        if(this.connectedCallbackLoopPrevention) {
            // this.make = this.asset.make;
            // this.assetType = this.asset.assetType;
            // this.model = this.asset.model;
            this.connectedCallbackLoopPrevention = false;
        } else {
            //console.log('connectedCallback has already been run in this lifecycle so we need to prevent recursion');
        }

    }



    @wire(getModels, {programId: '$programId', make: '$makeId', assetType: null})
    wiredGetModels({error, data}) {
        if(data) {
            console.log('getModels returned data');
            //console.log(data);
            let resArray = JSON.parse(data);

            console.log(resArray);

            if(resArray && resArray.length && resArray.length > 0) {
                this.processModelObjects(resArray);
            } else {
                this.showToast('Error getting models for an Asset', 'No Models available for this Class.', 'warning');
                console.log('getModels returned, but has no results');    
                let tempAsset = JSON.parse(JSON.stringify(this.asset));
                tempAsset.assetType = undefined;
                tempAsset.assetTypeId = undefined;
                // this.assetType = {value: null, label: null};
                const assetEvent = new CustomEvent("updateasset", {
                    detail: tempAsset
                })

                this.dispatchEvent(assetEvent);
            }

            // this.modelPicklist = mlist;
        } else if(error) {
            console.log('getModels returned an error');
            //console.log(error);
            let errorMessage = (error.body && error.body.message) ? error.body.message : 'API request Failre detected';
            this.showToast('ERROR: Failed to request Models for Selected Make', errorMessage, 'error');
        } else {
            console.log('getModels failed to return data or an error');
        }
    
    }
    
    processModelObjects(dataArray) {
        let allModelObjects = [];
        if(dataArray && dataArray.length && dataArray.length > 0) {
            dataArray.forEach(element => {
                if(element.catalog && element.catalog.identifiers && element.catalog.identifiers.structure) {
                    allModelObjects.push({
                        value: element.id,
                        label: element.catalog.identifiers.structure.model, 
                        modelId: element.catalog.id,
                        type: element.catalog.identifiers.structure.type,
                        brand: element.catalog.identifiers.structure.brand,
                        masterType: element.catalog.identifiers.structure.masterType,
                        assetType: element.catalog.identifiers.structure.category
                    });
                }
            });
    
            console.log('allModelObjects');
            console.log(allModelObjects);

            let allApplicableAssetTypes = [];
            allModelObjects.forEach(obj => {
                allApplicableAssetTypes.push(obj.assetType);
            });
    
            this.assetTypePicklist = this.sortAndGeneratePicklistValues(allApplicableAssetTypes);
            this.loadingAssetTypes = false;
    
            if(this.assetTypePicklist && this.assetTypePicklist.length) {
    
                this.modelPicklist = allModelObjects;
    
                if(this.assetTypePicklist.length === 1 && !this.assetTypeId) {
                    console.log('Autoselecting an asset type because the list of available is one long and there is not already a selection made'); 
                    let fakeSelectionEvent = {
                        detail: {
                            value: this.assetTypePicklist[0].value
                        }
                    };
                    // this.modelPicklistFiltered = this.modelPicklist;
                    this.handleChangeAssetType(fakeSelectionEvent);

                } else if(this.assetTypeId) {
                    console.log('Already selected an assettype, likely by defaulting from parent, need to render the associated models'); 
                    this.trimAvailableModelsByAssetType();
                } else {
                    console.log('Didnt process an assettype default because the assetTypePicklist size is ' + this.assetTypePicklist.length + ' and the assetTypeId is ' + this.assetTypeId);
                }
            } else {
                console.log('Didnt compile an assetTypePicklist for the given make... This should really never be the case');
            }
        }
    }
    
    getOtherInformation() {

        getAsset({  programId: this.programId, assetId: this.modelId })
            .then(result => {
                console.log('getAsset returned some data')
                this.loading=true;

                //console.log(JSON.parse(result));

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

            }).catch(error => {
            console.log('getOtherInformation threw an error');
            let errorMessage = (error.body && error.body.message) ? error.body.message : 'API request Failre detected';

            this.showToast('Error getting other info for an Asset', errorMessage, 'error');

            loadsToGo--;
            if (loadsToGo === 0) {
                this.loading = false;
            }
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
    
    handleChangeSalesPrice(event) {
        let tempAsset = JSON.parse(JSON.stringify(this.asset));
        let trimmedPrice = event.target.value.toString();
        trimmedPrice = trimmedPrice.split('.');
        if (trimmedPrice.length === 0) {
            trimmedPrice = 0;
        } else if (trimmedPrice.length === 1) {
            trimmedPrice = parseInt(trimmedPrice[0]);
        } else {
            if (trimmedPrice[1].length > 1) {
                trimmedPrice = trimmedPrice[0] + '.' + trimmedPrice[1].substring(0, 2);
            } else if (trimmedPrice[1].length === 1) {
                trimmedPrice = trimmedPrice[0] + '.' + trimmedPrice[1];
            } else {
                trimmedPrice = trimmedPrice[0] + '.';
            }
        }
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

    handleChangeMake(event) {  

        console.log('handleChangeMake is running');

        if(event.detail) {
            let selectedMakeValue = event.detail.value;
            console.log('changing the make to ' + selectedMakeValue);
            if(typeof this.asset.make === 'undefined' || !this.makeId) {
                this.loadingAssetTypes = true;

                console.log('Event handleChangeMake appears to be setting a brand new make value');

                let makeObj = event.detail;

    
                let tempAsset = JSON.parse(JSON.stringify(this.asset));
                tempAsset.make = makeObj;
                const assetEvent = new CustomEvent("updateasset", {
                    detail: tempAsset
                })
        
                this.dispatchEvent(assetEvent);    
                // this.triggerModelRequestIfNeeded();
            } else if(this.asset.make.value && this.asset.make.value !== selectedMakeValue) {
                if(!selectedMakeValue) {
                    console.log('Event handleChangeMake appears to be removing an existing make value altogether');
                    this.loadingAssetTypes = false;
                } else {
                    console.log('Event handleChangeMake appears to be setting a new and different/non-null make value');
                    this.loadingAssetTypes = true;

                }
    
                let makeObj = event.detail;
        
                let tempAsset = JSON.parse(JSON.stringify(this.asset));
                tempAsset.make = makeObj;
                tempAsset.assetType = {};
                tempAsset.model = {};
                tempAsset.unitSalesPrice = 0;
                tempAsset.numberOfUnits = 1;
                const assetEvent = new CustomEvent("updateasset", {
                    detail: tempAsset
                })
        
                this.dispatchEvent(assetEvent);

            } else if(this.asset.make.value && this.asset.make.value === selectedMakeValue) {

                console.log('Event handleChangeMake appears to be running on the same value that already exists');
                
                if(this.assetTypeId) {
                    let fakeSelectionEvent = {
                        detail: {
                            value: this.assetTypeId
                        }
                    };
                    this.handleChangeAssetType(fakeSelectionEvent);    
                } else {
                    console.log('this.asset');
                    console.log(this.asset);
                    
                    console.log(this.assetTypeId + ' is the this.assetTypeId');
                }

            } else {
                console.log('Failed to catch the response in the handleChangeMake call ');
            }
        } else {
            console.log('Failed to present a change object for the updated make');
        }

    }

    handleChangeAssetType(event) {
        console.log('handleChangeAssetType is running');

        if(event.detail.value) {
            let selectedAssetTypeValue = event.detail.value;
            console.log('Detected a selectedAssetType value of ' + selectedAssetTypeValue);
            if(typeof this.asset.assetType === 'undefined' || !this.assetTypeId) {
                console.log('setting the brand new asset type to ' + selectedAssetTypeValue);
                let selectedAssetTypeObject = this.assetTypePicklist.find(opt => opt.value === selectedAssetTypeValue);


                if(selectedAssetTypeObject) {
                    this.loadingModels = true;

                    let tempAsset = JSON.parse(JSON.stringify(this.asset));

                    tempAsset.assetType = selectedAssetTypeObject;
                    console.log('SEt the tempAssets assetType value to ' + selectedAssetTypeObject);
                    const assetEvent = new CustomEvent("updateasset", {
                        detail: tempAsset
                    })
        
                    this.dispatchEvent(assetEvent);   
                    
                    this.trimAvailableModelsByAssetType();
                } else {
                    console.log('Failed to locate the assetType object with the value of ' + selectedAssetTypeValue);
                }
            } else if(this.assetTypeId && this.assetTypeId !== selectedAssetTypeValue) {
                this.loadingModels = true;

                console.log('handleChangeAssetType appears to be setting a new and different assetType value');

                let assetTypeObj = event.detail;
        
                let tempAsset = JSON.parse(JSON.stringify(this.asset));
                tempAsset.assetType = assetTypeObj;
                tempAsset.model = null;
                const assetEvent = new CustomEvent("updateasset", {
                    detail: tempAsset
                })
        
                this.dispatchEvent(assetEvent);
                this.trimAvailableModelsByAssetType();

            } else if(this.assetTypeId && this.assetTypeId === selectedAssetTypeValue) {
                console.log('Appear to be changing the assetType value to the same exact value for some reason');
            }
        } else {
            console.log('Failed to present a change object for the updated asset type');
        }

        this.loadingModels = false;

    }

    trimAvailableModelsByAssetType() {

        let selectedAssetTypeValue = this.assetTypeId;
        let bufferArray = [];
        if(this.modelPicklist && this.modelPicklist.length) {
            console.log(this.modelPicklist);
            this.modelPicklist.forEach(modelObj => {
                //console.log(modelObj);
                if(modelObj.assetType === selectedAssetTypeValue) {
                    bufferArray.push(modelObj);
                }
            });

            this.modelPicklistFiltered = bufferArray;
            if(bufferArray.length === 1) {
                let fakeSelectionEvent = {
                    detail: {
                        label: bufferArray[0].label,
                        value: bufferArray[0].value
                    }
                };

                this.handleChangeModel(fakeSelectionEvent);
            }
        } else {
            console.log('MAJOR ERROR: This should never run');
            console.log('Set the asset type to ' + selectedAssetTypeValue + ', but dont have a list of models this means that we need to rerequest one');
        }

    }

    handleChangeModel(event) {
        console.log('handleChangeModel is running');
        if(event.detail.value) {

            let selectedModelId = event.detail.value;
            if(typeof this.asset.model === 'undefined' || !this.modelId) {
                console.log('setting the brand new model value to ' + selectedModelId);

                //console.log(selectedModelId);
                let modelObject = this.modelPicklistFiltered.find(obj => obj.value === selectedModelId);
                //console.log(modelObject);
                // this.model = modelObject;
                let tempAsset = JSON.parse(JSON.stringify(this.asset));
                tempAsset.model = modelObject;

                const assetEvent = new CustomEvent("updateasset", {
                    detail: tempAsset
                })

                this.dispatchEvent(assetEvent);    
                // this.getOtherInformation();
            } else if(this.modelId && this.modelId !== selectedModelId) {
                console.log('setting the new and different model value from ' + this.modelId +' to ' + selectedModelId);

                //console.log(selectedModelId);
                let modelObject = this.modelPicklistFiltered.find(obj => obj.value === selectedModelId);
                //console.log(modelObject);
                // this.model = modelObject;
                let tempAsset = JSON.parse(JSON.stringify(this.asset));
                tempAsset.model = modelObject;

                const assetEvent = new CustomEvent("updateasset", {
                    detail: tempAsset
                })

                this.dispatchEvent(assetEvent);    

            } else if(this.modelId && this.modelId === selectedModelId) {
                console.log('Appear to be changing the model value to the same exact value for some reason');
            } else {
                console.log('Uncaught scenario for the changeModel function');
            }
        } else {
            console.log('Failed to present a change object for the updated asset type');
        }
        //console.log('handleChangeModel finished');

    }




    triggerModelRequestIfNeeded() {
        
        if(this.makeId && this.assetTypeId) {
            //console.log(this.asset);
            //console.log(this.make);
            //console.log(this.assetType);
            // this.getModels();
        } else {
            this.disableModelPicklist = true;
            this.loading = false;
        }

    }

    sortAndGeneratePicklistValues(dataArray) {

        if(!Array.isArray(dataArray) || dataArray.length === 0) return null;


        let uniqueArray = [... new Set(dataArray)];
        
        if(uniqueArray.length === 0) return null;
        let arrayObjectTypes = typeof uniqueArray[0];
        
        // Type check the first element of the data array to determine the type of sorting that needs to be run
        if(arrayObjectTypes === 'number') {
            uniqueArray.sort((a,b) => {
                return a - b;
            });
        } else {
            uniqueArray.sort();
        }

        //console.log(uniqueArray);        
        let sortedValuesObjectArray = [];
        uniqueArray.forEach(termLength => {
        sortedValuesObjectArray.push({
                value: termLength,
                label: termLength.toString()
            })
        })
    

        return sortedValuesObjectArray;

    }


    get makeId() {
        return (this.asset && this.asset.make && this.asset.make.value) ? this.asset.make.value : null;
    }

    get assetTypeId() {
        return (this.asset && this.asset.assetType && this.asset.assetType.value) ? this.asset.assetType.value : null;
    }

    get modelId() {
        return (this.asset && this.asset.model && this.asset.model.value) ? this.asset.model.value : null;
    }

}