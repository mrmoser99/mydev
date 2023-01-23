/**
 * @description       : LWC component for Submitting a Credit Application from an Opportunity. 
 * @author            : Adam Tolbert : DLL
 * @group             : Adam Tolbert : DLL
 * @last modified on  : 01-10-2023
 * @last modified by  : Adam Tolbert
**/
import getOpportunity from '@salesforce/apex/InternalCreditAppUtils.getOpportunity';
import getOpportunityLines from '@salesforce/apex/InternalCreditAppUtils.getOpportunityLineData';
import UpdateOpportunityData from '@salesforce/apex/InternalCreditAppUtils.updateOpportunityData';
import getPrograms from "@salesforce/apex/AssetUtils.getPrograms";
import getFinancialProducts from '@salesforce/apex/AssetUtils.getFinancialProducts';
import getFinancialProduct from '@salesforce/apex/AssetUtils.getFinancialProduct';
import getMakes from '@salesforce/apex/AssetUtils.getMakes';
import acctNameById from '@salesforce/apex/AssetUtils.accountNameById';
import submitCreditApp from '@salesforce/apex/InternalCreditAppUtils.submitCreditAppRequest';
import {api, track, LightningElement, wire} from 'lwc';
import {CurrentPageReference} from 'lightning/navigation';
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';

import CREDITAPP_SUBMITTED_TITLE from '@salesforce/label/c.CREDITAPP_SUBMITTED_TITLE';
import CREDITAPP_SUBMITTEDERROR_400_500 from '@salesforce/label/c.CREDITAPP_SUBMITTEDERROR_400_500';
import CREDITAPP_SUBMITTEDERROR_404 from '@salesforce/label/c.CREDITAPP_SUBMITTEDERROR_404';
import CREDITAPP_SUBMITTEDERROR_GENERAL from '@salesforce/label/c.CREDITAPP_SUBMITTEDERROR_GENERAL';
import CREDITAPP_SUBMITTEDERROR_MESSAGE from '@salesforce/label/c.CREDITAPP_SUBMITTEDERROR_MESSAGE';
import CREDITAPP_SUBMITTEDERROR_TITLE from '@salesforce/label/c.CREDITAPP_SUBMITTEDERROR_TITLE';


export default class CreditApplicationFromOpportunity extends NavigationMixin(LightningElement) {

  
    @api recordId;
    @api objectApiName;

    //active section
    @track activeSections = ['Financing Structure', 'Customer Information', 'Program Information'];
    activeAssetSections = ["asset1"];
    
    /* Params from Url */
    oppId = null;

    //Model Pop-up on click of cancel button
    isModalOpen = false;

    refreshCustomerQuickSearch = true; 
    isAmountDisabled = false;

    //Object model
    applicationNameValue;
    salesRepObject;
    nicknameValue;
    selectedLocation;
    locationList=[];
    salesReplist=[];

    //finance structure
    inputPaymentAmount;
    inputFinanceTerm;
    // selectedFinanceTerm;
    selectedFinanceType;
    selectedPaymentFrequency;
    financeTermPicklist;
    financeTypePicklist;
    frequencyPicklist;
    advancedPaymentsPicklist;

    selectedFinancialProductConfigs;

    //assets
    @track assets = [{
        sectionName: 'asset1',
        assetHeading: 'Asset 1',
        assetNo: 1,
        isFirst: true,
        make:{},
        assetType:{},
        model:{},
        mastTypeValue:'',
        assetOperatingEnvironmentValue:'',
        annualHoursValue:'',
        batteryIncludedValue:'',
        numberOfUnits: 1,
        unitSalesPrice: 0,
        extendedPrice: 0,
        subsidyValue:'',
        assetId:''
    }];
    assetConditionPicklist = [
        {label: 'New Asset', value: 'New'},
        {label: 'Used Asset', value: 'Used'}
    ];

    selectedProgram;
    selectedFinancialProduct;
    // asset picklist options
    programPicklist;
    financialProducts;
    financialProductsPicklist;
    makePicklist = [];
    assetTypePicklist;
    modelPicklist;
    mastTypePicklist;
    assetOperatingPicklist;
    batteryIncludedPicklist;
    subsidyPicklist;
    assetsBlank= [];
    delaytimeout;
    @track loading = false;
    @track loadingPrograms = false;
    @track loadingFinanceTypes = false;
    @track loadingFinancialProducts = false;
    @track loadingPaymentFrequencies = false;
    @track loadingFinanceTerms = false;
    @track renderSummary = false;


    //accesssory picklist options
    relatedAssetPicklist;
    accessoryPicklist;
    unitSalesPricePicklist;
    numberofUnitsPicklist;
    endUserAccountId = null;
    endUserAccountName = null;

    customerInfoShow;

    salesRep;
    salesRepId;
    @track siteList = [];


    // timeout;

    // primeExtendedLoadingMessage() {
    //     this.timeout = setTimeout(() => {
    //         this.loadingText = 'Still loading... Apologies for the delay!';
    //     }, 500);
    
    // }
    
    //customerTrue=false;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            console.log('currentPageReference::'+JSON.stringify(currentPageReference.attributes.recordId));
            console.log('currentPageReference.state::'+JSON.stringify(currentPageReference.state));
            // Only the standard opportunity page is being used now.
            console.log(currentPageReference);
            this.oppId = currentPageReference.state.recordId;

            // The read/write page layouts are hidden by default, but then modified based on the opportunity status.
            // this.appEditMode = 'hide';


        }
    }


    pageReference;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if (currentPageReference) {
            console.log(currentPageReference);
            this.pageReference = {};
            this.pageReference.attributes = {};
            this.pageReference.attributes.recordId = this.oppId;
            this.pageReference.attributes.actionName = 'view';
            this.pageReference.type = 'standard__recordPage';
            console.log('page reference');
            console.log(JSON.parse(JSON.stringify(this.pageReference)));
            //this.setCurrentPageIdBasedOnUrl();
        }
    }

    @wire(acctNameById, {acctId: '$endUserAccountId'})
    wiredAcctNameById({ error, data }) {
        console.log('this.wiredAcctNameById ran on the recordId ' + this.endUserAccountId);
        if (data) {
            this.endUserAccountName = data;
        } else if(error) {
            console.log('wiredAcctNameById error detected');
            console.log(error);
        }
        else {
            console.log('acctNameById failed to locate any account with the Id of ' + this.endUserAccountId)
        }
    }
        



    @wire(getOpportunity, {opportunityId: '$recordId'})
    wiredGetOpportunity({ error, data }) {
        console.log('this.wiredGetOpportunity ran on the recordId ' + this.recordId);
        if (data) {
            console.log('getOpportunity data');
            console.log(data);
            let dataObj = JSON.parse(data);
            console.log('getOpportunity dataObj');
            console.log(dataObj);
            // let assetLen = 0;

            // const formatter = new Intl.NumberFormat('en-US', {
            //     style: 'currency',
            //     currency: 'USD',
            //     minimumFractionDigits: 2
            // });
            if(dataObj.accountSiteId) {
                console.log('data.accountSiteId exists');
                let locationObj = {
                    value: dataObj.accountSiteId,
                    label: dataObj.accountName + ' (' + dataObj.accountSiteId + ')'
                };
                this.siteList = [locationObj];
                this.loadingText = "Loading Programs... Please Wait...";
                this.loadingPrograms = true;

                this.selectedLocation = locationObj.value;

            }

            if(dataObj.endUserId) {
                this.endUserAccountId = dataObj.endUserId;
            }

        } else if (error) {
            console.log('getOpportunity error');
            console.log(error);        
            const evt = new ShowToastEvent({
                title:      'Error Retrieving Opportunity',
                message:    error.body.message,
                variant:    'error',
                duration:   20000
            });
            this.dispatchEvent(evt);

        } else {
            console.log('No Data nor Error in wiredGetOpportunity');
        }
    }

    @wire(getOpportunityLines, {opportunityId: '$recordId'})
    wiredGetOpportunityLines({ error, data }) {
        console.log('this.wiredGetOpportunityLines ran on the recordId ' + this.recordId);
        if (data) {
            console.log('getOpportunityLines data');
            console.log(data);
            let assetLen=0;

            const formatter = new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD',
                minimumFractionDigits: 2
            })
            let bufferArray = [];
            for(let i=0;i<data.length;i++) {
                assetLen=i+1;
                bufferArray.push({
                    sectionName: 'asset' + assetLen,
                    assetHeading: 'Asset ' + assetLen,
                    assetNo: assetLen,
                    isFirst: true,
                    makeValue:data[i].Make__c,
                    assetTypeValue:data[i].Asset_Type_ITA_Class__c,
                    modelValue:data[i].Model__c,
                    mastTypeValue:data[i].Mast_Type__c,
                    assetOperatingEnvironmentValue:data[i].Operating_Environment__c,
                    annualHoursValue:data[i].Annual_Hours__c,
                    batteryIncludedValue:data[i].Battery_Included__c,
                    numberOfUnitsValue:data[i].Number_of_Units__c.toString(),
                    unitSalesPriceValue: (data[i].Base_Unit_Sales_Price__c != null && data[i].Base_Unit_Sales_Price__c !== undefined && data[i].Base_Unit_Sales_Price__c !== '') ? formatter.format(data[i].Base_Unit_Sales_Price__c.toFixed(2)) : '',
                    subsidyValue:data[i].Subsidy__c,
                    assetId:data[i].Id,
                    quoteId: data[i].Quote__c // Used to map to submitCreditApp()
                });
            }

            if(bufferArray.length > 0) {
                this.assets = bufferArray;
            }

        } else if (error) {
            console.log('getOpportunityLines error');
            console.log(error);        
        } else {
            console.log('No Data nor Error in wiredGetOpportunityLines');
        }
    }

    @wire(getPrograms, {siteName: '$selectedLocation'})
    wiredGetPrograms({ error, data }) {
        console.log('wiredGetProgram ran on selected location ' + this.selectedLocation);

        if(data) {
            console.log('wiredGetProgram has data');
            console.log(data);
            
            let plist = [];
            let dataArray = JSON.parse(data);
            console.log(dataArray);

            dataArray.forEach(element => {
                console.log(element);
                console.log(element.programName + ' ' + element.programId);
                let compiledLabel = element.programName;
                compiledLabel += (
                    element.programId.includes('-') ? 
                    (' ( ...-' + element.programId.split('-')[1] + ' )') : 
                    ''
                );

                plist.push({label: compiledLabel, value: element.programId});
            });

            this.programPicklist = plist;


        } else if(error) {
            console.log('wiredGet Programs threw an error');
            console.log(error);
            console.log(JSON.parse(JSON.stringify(error)));
            this.showToast('ERROR: Failed to request Program data', error.body.message, 'error');
            this.programPicklist = [];

        } else {
            console.log('No Data nor Error in wiredGetPrograms');
            console.log(this.selectedLocation);
        }

        this.loadingPrograms = false;

    }



    @wire(getFinancialProducts, {programId: '$selectedProgramId', financetype: null, newused: null})
    wiredGetFinancialProducts( {error, data} ) {
        console.log('wiredGetFinancialProducts ran on selected program ' + this.selectedProgramId);

        if(data) {
            console.log('wiredGetFinancialProducts has data');
            console.log(data);
            
            let prodlist = [];
            let financeTypesArray = [];
            let dataArray = JSON.parse(data);
            this.financialProducts = dataArray;

            console.log(dataArray);
            dataArray.forEach(prod => {
                console.log(prod.id + ' ' + prod.name);
                prodlist.push({label: prod.name, value: prod.id});
                if(prod.purchaseOptions && prod.purchaseOptions.length) {
                    prod.purchaseOptions.forEach(optionString => {
                        financeTypesArray.push(optionString);
                    });
                }
            });

            console.log(financeTypesArray);
            this.financeTypePicklist = this.sortAndGeneratePicklistValues(financeTypesArray);
            this.loadingFinanceTypes = false;

            this.financialProductsPicklist = prodlist;
            // setTimeout(() => {
            //     loadsToGo--;
            //     if (loadsToGo === 0) {
            //         this.loading = false;

            //         console.log('handleChangeLocation done2');
            //     }
            // }, 1500);
        } else if(error) {
            console.log('wiredGetFinancialProducts threw an error');
            console.log(error);
            console.log(JSON.parse(JSON.stringify(error)));
            this.showToast('ERROR: Apex exception thrown', error.body.message, 'error');
            this.loadingFinanceTypes = false;
            this.selectedProgram = null;
            // loadsToGo--;
            // if (loadsToGo === 0) {
            //     this.loading = false;
            // }

        } else {
            console.log('No Data nor Error in wiredGetFinancialProducts');
            console.log(this.selectedLocation);
        }

        this.requestProgramsAvailableMakes();
    }
 
    requestProgramsAvailableMakes() {
        console.log('requestProgramsAvailableMakes running on selected program ' + this.selectedProgramId);
        if(!this.selectedProgramId) return;
        getMakes({programId: this.selectedProgramId })
        .then(res => {
            console.log('requestProgramsAvailableMakes call returned res');
            console.log(res);
            let mlist = [];
            let data = JSON.parse(res);
            console.log(data);
            if(data && data.length) {
                console.log('requestProgramAvailableMakes returned a total of ' + data.length + ' different makes');
                data.forEach(function (element) { 
                    mlist.push({label: element.makeName, value: element.makeId});
                });
                this.makePicklist = mlist;
                this.loading = false;
            } else {
                console.log('requestProgramsAvailableMakes res was incomprehensible and/or falsey');
            }
            
        })
        .catch(err => {
           console.log(err);
           if (this.programId) {
               this.showToast('Something went wrong trying to get makes', err, 'error');
               this.makePicklist = [];
               console.log('Neither data nor error were returned in the wiredgetMakes call');
           }
        });
       

    }



    @wire(getFinancialProduct, {programId: '$selectedProgramId', productId: '$selectedProductId', newused: 'new'})
    wiredGetFinancialProduct( {error, data} ) {
        console.log('getFinancialProduct ran on selected program ' + this.selectedProgramId);
        console.log('getFinancialProduct ran on selectedProductId ' + this.selectedProductId);

        if(data) {
            console.log('getFinancialProduct has data');
            console.log(data);
            let dataObj = JSON.parse(data).data;
            // this.loadingPaymentFrequencies = true;
            this.processFinancialProduct(dataObj);
            

            // this.processFinancialProduct(dataObj);
        } else if(error) {
            console.log('getFinancialProduct threw an error');
            console.log(error);
            console.log(JSON.parse(JSON.stringify(error)));
            this.showToast('Something went wrong', error.body.message, 'error');
            this.programPicklist = [];

        } else {
            console.log('No Data nor Error in getFinancialProduct');
            console.log(this.selectedProductId);
            if(this.selectedProductExists) {
                console.log('processing a fake product object');
            }

        }


    }
    

    processFinancialProduct(dataObj) {
        
        console.log(dataObj);

        let frequencyObjects = [];
        if(dataObj.duration && dataObj.duration.numberOfMonths && dataObj.duration.numberOfMonths.values && dataObj.duration.numberOfMonths.values.length) {
            dataObj.duration.numberOfMonths.values.forEach(dur => {
                let frequency = dur.inputs.paymentFrequency;
                
                frequencyObjects.push({ value:frequency, label:frequency, min:dur.minimum, max:dur.maximum });
            });
        } else if(dataObj.duration && dataObj.duration.numberOfmonths && dataObj.duration.numberOfmonths.values && dataObj.duration.numberOfmonths.values.length) {
            dataObj.duration.numberOfmonths.values.forEach(dur => {
                let frequency = dur.inputs.paymentFrequency;
                
                frequencyObjects.push({ value:frequency, label:frequency, min:dur.minimum, max:dur.maximum });
            });
        }


        console.log('frequencyObjects');
        console.log(frequencyObjects);
        this.frequencyPicklist = frequencyObjects;
        this.loadingPaymentFrequencies = false;


        let financeAmount = {minimum: 0, maximum: 1};
        if(dataObj.finance && dataObj.finance.financeAmount) {
            financeAmount = dataObj.finance.financeAmount;
        }
        console.log(financeAmount);
        this.financeBoundaries = financeAmount;
        


        let financialProductConfigurations = [];
        if(dataObj.finance && dataObj.finance.rateFactors && dataObj.finance.rateFactors.nominalRate && dataObj.finance.rateFactors.nominalRate.percentages && dataObj.finance.rateFactors.nominalRate.percentages.length) {
            console.log(dataObj.finance);
            console.log(dataObj.finance.rateFactors);
            console.log(dataObj.finance.rateFactors.nominalRate);
            console.log(dataObj.finance.rateFactors.nominalRate.percentages);
            dataObj.finance.rateFactors.nominalRate.percentages.forEach(config => {
                financialProductConfigurations.push({
                    frequency: config.inputs.paymentFrequency,
                    leaseType: config.inputs.purchaseOption,
                    durationLimit: config.inputs.numberOfMonths,
                    makes: config.inputs.assetBrandNames,
                    models: config.inputs.assetModelNames,
                    conditions: config.inputs.assetConditions,
                    rate: config.outputs.rate
                });
            });
        }

        console.log('financialProductConfigurations');
        console.log(financialProductConfigurations);

        this.selectedFinancialProductConfigs = financialProductConfigurations;

        let allApplicableAssetMakes = [];
        // let allApplicableFinanceTermLengths = [];
        // let allApplicableFrequencies = [];

        financialProductConfigurations.forEach(config => {
            console.log(config);
            if(config.makes && config.makes.length) {
                allApplicableAssetMakes = allApplicableAssetMakes.push(config.makes);
            }
            // if(config.frequency && !allApplicableFrequencies.includes(config.frequency)) {
            //     allApplicableFrequencies.push(config.frequency);
            // }
            // if(config.durationLimit) {
            //     if(!allApplicableFinanceTermLengths.includes(config.durationLimit)) {
            //         allApplicableFinanceTermLengths.push(config.durationLimit);
            //     }
            // }
        });

        // console.log(allApplicableFrequencies);
        // this.frequencyPicklist = this.sortAndGeneratePicklistValues(allApplicableFrequencies);
        // this.loadingPaymentFrequencies = false;


        console.log(allApplicableAssetMakes);

        if(allApplicableAssetMakes.length > 0) {
            let tempArray = [];
            allApplicableAssetMakes.forEach(make => {
                if(tempArray.includes(make)) {
                    console.log('allApplicableAssetMakes already has make ' + make);
                } else {
                    allApplicableAssetMakes.push(make);
                }
            });

            let applicableMakeObjects = [];
            tempArray.forEach(uniqueMake => {
                let thisMakeObj = this.makePicklist.find(el => el.value === uniqueMake); 
                applicableMakeObjects.push(thisMakeObj);                   
            });
            console.log(applicableMakeObjects);

            this.makePicklist = applicableMakeObjects;

        } else {
            console.log('No asset makes are defined explicitally in this product selection, this means we cover all types of makes available to the program');
            console.log('The current list of all makes available to this program is ' + this.makePicklist.length + ' units long');
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

        console.log(uniqueArray);        
        let sortedValuesObjectArray = [];
        uniqueArray.forEach(uniqueValue => {
        sortedValuesObjectArray.push({
                value: uniqueValue,
                label: uniqueValue.toString()
            })
        })
    

        return sortedValuesObjectArray;

    }


    populateProductPicklistValues() {

        let allProductObjects = this.financialProducts;
        console.log(allProductObjects);

        console.log('this.selectedFinanceType is...');
        console.log(this.selectedFinanceType);
        let currentFinanceTypeId = this.selectedFinanceTypeId;
        console.log('currentFinanceTypeId is...');
        console.log(currentFinanceTypeId);

        let bufferArray = [];

        let standardRatesObject = {label: null, value: null};
        allProductObjects.forEach(config => {
            console.log(config);
            if(config.purchaseOptions.includes(currentFinanceTypeId)) {
                bufferArray.push({label: config.name, value: config.id});
                if(config.name === 'Standard Rates') {
                    standardRatesObject = {label: config.name, value: config.id};
                }
            }
        });


        console.log('populateProductPicklistValues bufferArray is...');
        console.log(bufferArray);

        this.financialProductsPicklist = bufferArray;
        if(bufferArray.length === 1) {
            this.selectedFinancialProduct = bufferArray[0];
            this.loadingText = "Loading Payment Frequencies... Please Wait...";
            this.loadingPaymentFrequencies = true;
        } else if(standardRatesObject.label != null) {
            this.selectedFinancialProduct = standardRatesObject;
            this.loadingText = "Loading Payment Frequencies... Please Wait...";
            this.loadingPaymentFrequencies = true;
        }
        
        this.loadingFinancialProducts = false;

    }
    
    setFinanceTypePicklist(picklistValues) {
        this.financeTypePicklist = picklistValues;
    }

    connectedCallback() {
    }

    updateAmountOnStory(event) {
        this.customerStory.amount = Number(event.detail.value).toFixed(2).toString();
    }

/*
    @api
    customerInfoSectionHide() {
        this.customerTrue=false;
    }
*/
    handleAddAsset() {
        this.loading = true;
        // let assetsSize = this.assets.length + 1;
        let lowestMissingAssetNo = this.findFirstMissingAssetNo();
        this.assets.push({
            sectionName: 'asset' + lowestMissingAssetNo,
            assetHeading: 'Asset ' + lowestMissingAssetNo,
            assetNo: lowestMissingAssetNo,
            numberOfUnits: 1,
            unitSalesPrice: 0,
            extendedPrice: 0,    
            isFirst: false
        });
        this.loading=false;

    }
    
    findFirstMissingAssetNo() {
        let nums = this.assets.map(asset => asset.assetNo);

        let swap = function(i, j) {
            let tmp = nums[i];
            nums[i] = nums[j];
            nums[j] = tmp;
        };
    
        for (let i = 0; i < nums.length; i++) {
            while (0 < nums[i] && nums[i] - 1 < nums.length
                    && nums[i] !== i + 1
                    && nums[i] !== nums[nums[i] - 1]) {
                swap(i, nums[i] - 1);
            }
        }
    
        for (let i = 0; i < nums.length; i++) {
            if (nums[i] !== i + 1) {
                return i + 1;
            }
        }
        return nums.length + 1;
    }

    handleRemoveAsset(event) {
        console.log('handleRemoveAsset running');
        console.log(event);
        console.log(event.target);
        console.log(event.target.value);

        let assetNumberToDelete = -1;
        if(event.target && event.target.value) {
            assetNumberToDelete =event.target.value;
        } else {
            assetNumberToDelete = event.detail;
        }
        console.log('Attempting to locate and delete the asest with the assetNo of ' + assetNumberToDelete);

        let assetUpdatedIndex = this.assets.findIndex(ast => ast.assetNo === assetNumberToDelete);
        
        if(assetUpdatedIndex && assetUpdatedIndex !== -1) {
            this.assets.splice(assetUpdatedIndex, 1);
        }
        // for(let i=0;i<this.assets.length;i++) {
        //     assetLen=assetLen+1;
        //     if(this.assets[i].assetNo === event.target.dataset.item) {
        //         assetLen=assetLen-1;
        //     } else {
        //         this.assets[i].sectionName='asset'+assetLen;
        //         this.assets[i].assetHeading='Asset '+assetLen;
        //         this.assets[i].assetNo=assetLen;
        //         newAssets.push(this.assets[i]);
        //     }
        // }
        // this.assets=newAssets;
    }

    handleUpdateAsset(event) {
        console.log('handleUpdateAsset running');

        this.loading = true;
        
        console.log(event);
        console.log(event.detail);
        let obj = event.detail;
        console.log(obj);
        console.log(obj.assetNo);
        let assetNumber = obj.assetNo;

        let assetUpdatedIndex = this.assets.findIndex(ast => ast.assetNo === assetNumber);
        console.log('Located an assetindex of ' + assetUpdatedIndex);
        if(assetUpdatedIndex !== -1) {
            console.log('Located an asset matching the assetNo of the updated event');

            let assetToUpdate = this.assets[assetUpdatedIndex];
            assetToUpdate = obj;
            console.log(assetToUpdate);

            // Dynamically generate the Label of the Accordion Section
            assetToUpdate.assetHeading = 'Asset ' + (assetToUpdate.assetNo) + 
                ((assetToUpdate.make && assetToUpdate.make.label) ? ' | ' + assetToUpdate.make.label : '') + 
                ((assetToUpdate.model && assetToUpdate.model.label) ? ' - ' + assetToUpdate.model.label : '');

            assetToUpdate.extendedPrice = ((assetToUpdate.numberOfUnits) ? assetToUpdate.numberOfUnits : 0) * ((assetToUpdate.unitSalesPrice) ? assetToUpdate.unitSalesPrice : 0)
            this.assets.splice(assetUpdatedIndex, 1, assetToUpdate);
        } else {
            console.log('Failed to locate an asset in the list with an assetNo of ' + assetNumber);
        }


        // TODO Determine if the credit app shoule auto-hydrate itself based on current Quote_Line__c records under the primary quote.
        // The difficulty here would be that we may be populating the asset with asset makes and models that, because they are not from the API, are not applicable to the program and would likely cause errors in MOSAIC if sent  

        // this.assets.find((value, index) => {
        //     if(value.assetNo === assetNumber) {
        //         this.assets.splice(index, 1, obj);
        //     }
        // });
        // if(assetToUpdate) {
        //     console.log('Located an asset matching the assetNo of the updated event');
        //     console.log(assetToUpdate);
        //     console.log(assetToUpdate.assetNo);
        //     let assetUpdatedIndex = this.assets.findIndex(el => el.assetNo === assetNumber);
        //     console.log(assetUpdatedIndex);
        //     if(assetUpdatedIndex && assetUpdatedIndex !== -1) {
        //         console.log('Located an assetindex of ' + assetUpdatedIndex);
        //         this.assets.splice(assetUpdatedIndex, 1, assetBeingUpdated);
        //     } else {
        //         console.log('MAJOR ERROR: This should never run.');
        //         console.log('Failed to find an Index for the returned value');
        //     }
        // } else {
        //     console.log('Faioled to find any asset that matches the updateAsset events assetNo tag');
        // }

        // This appears to be ensuring that the array is still proplery allocated before updating by index value...
        // This is unnecessary and is quicker and more reliable to find the element with a key value and replace it 


        // for (let i = 0; i < this.assets.length; i++) {
        //     if (this.assets[i].modelId === this.assets[event.detail.assetNo].modelId && event.detail.assetNo !== i && event.detail.assetNo != undefined) {
        //         this.assets[event.detail.assetNo].modelId = undefined;
        //         event.detail.modelId = undefined;
        //         const evt = new ShowToastEvent({
        //         title:      CREDITAPP_ASSET_TITLE,
        //         message:    CREDITAPP_ASSET_DUP + ' ' + this.assets[i].model + '!',
        //         variant:    'error', 
        //         duration:   20000
        //         });
        //         this.dispatchEvent(evt);
        //         this.loading = false;
        //         return;
        //     }
        // }

        // this.assets[event.detail.assetNo] = event.detail;

        this.assets.forEach(asset => {
            console.log(asset);
            console.log(JSON.stringify(asset));
            console.log(JSON.parse(JSON.stringify(asset)));
        });

        this.loading = false;
        console.log('handleUpdateAsset finished');
    }

    updateAssetPicklist() {
        this.relatedAssets = [];
        for (let i = 0; i < this.assets.length; i++) {
            if (typeof this.assets[i].make !== 'undefined') {
                this.relatedAssets.push({label: this.assets[i].assetHeading, value: this.selectedProgramId + '!@#$%^&*(' + this.assets[i].makeId + '!@#$%^&*(' + this.assets[i].assetTypeId + '!@#$%^&*(' + this.assets[i].modelId + '!@#$%^&*(' + this.assets[i].assetNo + '!@#$%^&*(' + this.assets[i].make + '!@#$%^&*(' + this.assets[i].model});
            }
        }
    }



    // --------------------------------- model pop-up on click of cancel button--------------------------//
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }



    componentCancel() {
        this.updateRecordView(this.oppId);
        this.isModalOpen = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    isValidValues() {
        let isValid=true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    /**
     * First validate and save the credit application in Salesforce
     * Then callSubmitCreditApp()
     */
    handleSaveAndSubmit() {
        console.log('customerInfoShow::'+this.customerInfoShow);
        // let errorOccur = false;

    
        if(this.errorDetected === false) {
            this.loading=true;
            let customerStoryObj = {
                'financialProduct': this.selectedProductId,
                'amount': this.totalPrice,
                'salesRepId': null,
                'paymentFrequency': this.selectedPaymentFrequencyId,
                'paymentAmount': this.inputPaymentAmount,
                'financeType': this.selectedFinanceTypeId,
                'financeTerm': this.inputFinanceTerm
            };

            UpdateOpportunityData({ oppId: this.recordId, customerStory: customerStoryObj, assets: this.assets })
            .then(result =>{
                if(result) {
                    console.log(result);
                    this.updateRecordView(this.recordId);

                    this.appEditMode = true;

                    // Submit the credit app
                    this.callSubmitCreditApp();
                    

                } else {
                    console.log('handleOnSubmit 3');
                    this.loading=false;
                    this.appEditMode = true;

                    // Immediate feedback
                    const evt = new ShowToastEvent({
                        title:      'ERROR Detected',
                        message:    'Failed to Submit Credit App',
                        variant:    'error',
                        duration:   20000
                    });
                    this.dispatchEvent(evt);
                }
            }).catch(error=>{
                console.log('handleOnSubmit 4');
                console.log(error)
                this.loading=false;
                this.appEditMode = true;

                // Immediate feedback
                const evt = new ShowToastEvent({
                    title:      'ERROR Detected',
                    message:    error.toString(),
                    variant:    'error',
                    duration:   20000
                });
                this.dispatchEvent(evt);
            });
        }
    }

    // /*
    // * Perform the integrated callout and handle the response.
    // * */
    callSubmitCreditApp() {

        submitCreditApp({'oppId': this.recordId}).then(res =>{
            if(res) {
                console.log('submitCreditApp res');

                console.log(res);
                let result = JSON.parse(res);
                console.log(result);
                console.log('submitCreditApp: ' + result);

                // InternalCreditAppUtils returns a positive response object that looks like this...
                // {
                //  String status = 'OK';
                //  String errorMsg = null;
                //  String responseBody = "{json}";
                //  Integer responseCode = 200;
                // }

                if(result.responseCode === 200) {
                    console.log('200 result.responseCode');
                    this.showToast(CREDITAPP_SUBMITTED_TITLE, result.message, 'success');
                    this.componentCancel();
                } else {
                    console.log('result.responseCode');
                    console.log(result.responseCode);
                    this.loading = false;
                    this.showToast(CREDITAPP_SUBMITTEDERROR_TITLE, result.message, 'error');
                }
            } else {
                this.loading = false;
                this.showToast(CREDITAPP_SUBMITTEDERROR_TITLE, CREDITAPP_SUBMITTEDERROR_MESSAGE, 'error');
            }
        }).catch(error=>{
            console.log('submitCreditApp error');
            console.log(error);
            let cleanedErrorObject = JSON.parse(JSON.stringify(error));
            console.log('error submit credit app ::');
            console.log(cleanedErrorObject);
            let errorInfo = cleanedErrorObject.body ? cleanedErrorObject.statusText + ': ' + cleanedErrorObject.body.message : '';

            if(cleanedErrorObject.status === '404') {
                this.showToast(CREDITAPP_SUBMITTEDERROR_TITLE, errorInfo === '' ? CREDITAPP_SUBMITTEDERROR_404 : errorInfo, 'error');
            } else if(cleanedErrorObject.status === '400' || cleanedErrorObject.status === '500') {
                this.showToast(CREDITAPP_SUBMITTEDERROR_TITLE, errorInfo === '' ? CREDITAPP_SUBMITTEDERROR_400_500 : errorInfo, 'error');
            } else {
                this.showToast(CREDITAPP_SUBMITTEDERROR_TITLE, errorInfo === '' ? CREDITAPP_SUBMITTEDERROR_GENERAL : errorInfo, 'error');
            }
            this.loading = false;

        });
    }

    // -------------------model pop-up on click of Submit Credit Application button---------------------//
    /**
     * To check whether the customer approval check box is checked/unchecked.
     * @Param Holla {*} event
     */
    onClickOfCheckBox(event) {
        if(event.target.checked) {
            this.customerStory.acceptedCheckbox = true;
        } else{
            this.customerStory.acceptedCheckbox = false;
        }
    }


    //onchange function
    handleProgramChange(event) {
        this.loadingText = "Loading all Financial Products available to Program... Please Wait...";
        this.loadingFinanceTypes = true;
        this.selectedProgram = this.programPicklist.find(p => p.value === event.detail.value);
    }
    handleFinanceTypeChange(event) {
        this.loadingText = "Loading the subset of Financial Products outlined with that Finance Type... Please Wait...";
        this.loadingFinancialProducts = true;
        this.selectedFinanceType = this.financeTypePicklist.find(ft => ft.value === event.detail.value);
        this.populateProductPicklistValues();

        // this.selectedPaymentFrequency = null;
        // this.selectedFinanceTerm = null;
        // this.populatePaymentPicklistValues();
    }

    handlePaymentAmountChange(event) {
        console.log('handlePaymentAmountChange running');
        console.log(event.detail.value);
        let newPaymentValue = event.detail.value;
        this.inputPaymentAmount = newPaymentValue;
    }


    handleFinancialProductChange(event) {
        this.loadingText = "Loading the available Frequencies to the selected Financial Product... Please Wait...";
        this.loadingPaymentFrequencies = true;
        this.selectedFinancialProduct = this.financialProductsPicklist.find(fp => fp.value === event.detail.value);
        // wiredGetProduct method is responsible for reacting to this change via the 
    }
    handlePaymentFrequencyChange(event) {
        this.selectedPaymentFrequency = this.frequencyPicklist.find(freq => freq.value === event.detail.value);
        console.log('The new Selected payment Frequency is as follows:');
        console.log(this.selectedPaymentFrequency);
        // this.loadingFinanceTerms = true;
        // this.populateFinanceTermPicklistValues();
    }
    handleFinanceTermChange(event) {
        console.log('handleFinanceTermChange running');
        console.log(event.detail.value);
        let newTermValue = event.detail.value;
        // this.selectedFinanceTerm = this.financeTermPicklist.find(term => term.value === event.detail.value);
        if((this.financeTermMin && newTermValue < this.financeTermMin) || (this.financeTermMax && newTermValue > this.financeTermMax)) {
            console.log('The new value of ' + newTermValue + ' is outside the acceptable range');
            // this.selectedFinanceTerm = null;
        } else {
            // console.log('Setting the selected finance value to ' + event.detail.value);
            // console.log(this.financeTermPicklist);
            // let selectedObj  = this.financeTermPicklist.find(term => term.label === event.detail.value);
            // console.log(selectedObj);
        }        
        this.inputFinanceTerm = newTermValue;
        this.activeSections.push('Assets');
    }
    handleAssetTypeChange(event) {
        for(let i=0;i<this.assets.length;i++) {
            if(this.assets[i].assetNo === event.target.name) {
                this.assets[i].assetTypeValue=event.detail.value;
            }
        }
    }

    handleRenderSummary(event) {
        console.log(event);
        this.renderSummary = true;
    }

    handleHideSummary(event) {
        console.log(event);
        this.renderSummary = false;
    }


    handleCreditAppRedirect(event) {
        console.log('In handlecreditappredirect');
        if (event.detail === 'success') {
            this.updateRecordView(this.oppId);
        } else {
            console.log(event.detail);
            this.showToast('Error','Unsuccessful redirect to credit application page', 'error');
        }
    }

    handleCustomerInfoShow(event) {
        this.customerInfoShow=event.detail;

    }

    // Handle enroll in financing
     handleOnEnrolment() {
        console.log('Handle Enrolment process on Credit application page !!');
        this.loading = true;
        if(this.oppId != null && this.oppId !== undefined && this.oppId !== '') {
            this.loading = false;
            this[NavigationMixin.Navigate]({type: 'standard__webPage',attributes: {
                url: window.location.origin + '/dllondemand/s/enroll-screen?oppId=' + this.oppId
                }
            })
        }
    }

    showToast(title, message, variant) {
        let mode = 'sticky';

        if(variant !== null && variant.toLowerCase() === 'success') {
            mode = 'pester';
        } 
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

      //toggle for sections
      handleAssetSectionToggle(event) {
        const openSections = event.detail.openSections;
        this.openAccordionSections = openSections;
    }

    updateRecordView(recId) {
        updateRecord({fields: { Id: recId }});
    }


    get selectedLocationExists() {
        return (this.selectedLocation && this.selectedLocation != null) ? true : false;    
    }
    get missingLocationSelection() {
        return !this.selectedLocationExists;
    }

    get disableProgramSelection() {
        return (this.missingLocationSelection || (this.programPicklist && this.programPicklist.length === 0));
    }

    get selectedProgramId() {
        return (this.selectedProgram && this.selectedProgram.value) ? this.selectedProgram.value : null;    
    }
    get selectedProgramExists() {
        return (this.selectedProgram && this.selectedProgram.value) ? true : false;    
    }
    get missingProgramSelection() {
        return !this.selectedProgramExists;
    }


    get selectedProductId() {
        return (this.selectedFinancialProduct && this.selectedFinancialProduct.value) ? this.selectedFinancialProduct.value : null;    
    }
    get selectedProductExists() {
        return (this.selectedFinancialProduct && this.selectedFinancialProduct.value) ? true : false;    
    }
    get missingProductSelection() {
        return !this.selectedProductExists;
    }

    get financeAmountMinimum() {
        return (this.financeBoundaries && this.financeBoundaries.minimum) ? this.financeBoundaries.minimum : 0;
    }
    get financeAmountMaximum() {
        return (this.financeBoundaries && this.financeBoundaries.maximum) ? this.financeBoundaries.maximum : 0;
    }

    get selectedFinanceTypeName() {
        return (this.selectedFinanceType && this.selectedFinanceType.label) ? this.selectedFinanceType.label : null;    
    }
    get selectedFinanceTypeId() {
        return (this.selectedFinanceType && this.selectedFinanceType.value) ? this.selectedFinanceType.value : null;    
    }
    get selectedFinanceTypeExists() {
        return (this.selectedFinanceType && this.selectedFinanceType != null) ? true : false;
    }
    get missingFinanceTypeSelection() {
        return !this.selectedFinanceTypeExists || (this.financialProductsPicklist && this.financialProductsPicklist.length < 2);
    }

    get formattedPaymentAmountLabel() {
        if(this.selectedPaymentFrequency && this.selectedPaymentFrequency.value) {
            let freqVal = this.selectedPaymentFrequency.value.toLowerCase();
            if(freqVal.includes('annually')) {
                freqVal = freqVal.replace(/annually/g, 'Annual');
            }
            freqVal = freqVal[0].toUpperCase() + freqVal.substring(1);
            return freqVal + ' Payment Amount';
        } 

        return 'Payment Amount';
        
    }

    get selectedPaymentFrequencyId() {
        return (this.selectedPaymentFrequency && this.selectedPaymentFrequency.value) ? this.selectedPaymentFrequency.value : null;    
    }
    get selectedPaymentFrequencyExists() {
        return (this.selectedPaymentFrequency && this.selectedPaymentFrequency.value) ? true : false;    
    }
    get missingPaymentFrequencySelection() {
        return !this.selectedPaymentFrequencyExists;
    }

    get financeTermLabel() {
        return 'Finance Term (mo.) ' + (this.financeTermMin ?  this.financeTermMin + ' - ' : '') + (this.financeTermMax ?  this.financeTermMax : '');
    }
    get financeTermMin() {
        return (this.selectedPaymentFrequency && this.selectedPaymentFrequency.min) ? this.selectedPaymentFrequency.min : null;
    }
    get financeTermMax() {
        return (this.selectedPaymentFrequency && this.selectedPaymentFrequency.max) ? this.selectedPaymentFrequency.max : null;
    }
    get financeTermExists() {
        return (this.inputFinanceTerm && this.inputFinanceTerm != null) ? true : false;
    }
    get financeTermIsValid() {
        return (this.financeTermExists && (this.financeTermMin == null || this.financeTermMin <= this.inputFinanceTerm) && (this.financeTermMax == null || this.financeTermMax >= this.inputFinanceTerm));
    }
    get inputPaymentAmountExists() {
        return (this.inputPaymentAmount && this.inputPaymentAmount > 0) ? true : false;
    }

    get renderAssets() {
        return (this.selectedProgramExists && this.selectedProductExists && this.selectedFinanceTypeExists && this.selectedPaymentFrequencyExists && this.financeTermIsValid) ? true : false;        
    }

    get totalPrice() {

         if (this.assets && this.assets.length) {
            let sumVal = 0;
            this.assets.forEach(asset => {
                if(asset.extendedPrice) {
                    sumVal += asset.extendedPrice;
                } else {
                    console.log('The asset ' + asset.label + ' doesnt have an extendedPrice');
                }
            });
            return sumVal;
        } 

        return 0;

    }

    get disableReviewButton() {
        return (this.totalPrice === 0 || !this.renderAssets || this.loading) ? true : false;
    }

    get disableSubmitButton() {
        return this.loading;
    }

    get estimatedMonthlyPayment() {
        return (this.totalPaymentAmount / this.inputFinanceTerm);
    }

    get totalPaymentAmount() {
        
        if(this.inputPaymentAmountExists) {
            if(this.selectedPaymentFrequencyId === 'annually') {
                return this.inputPaymentAmount * (this.inputFinanceTerm / 12);
            } else if(this.selectedPaymentFrequencyId === 'semi-annually') {
                return this.inputPaymentAmount * (this.inputFinanceTerm / 6);
            } else if(this.selectedPaymentFrequencyId === 'quarterly') {
                return this.inputPaymentAmount * (this.inputFinanceTerm / 4);
            } else if(this.selectedPaymentFrequencyId === 'monthly') {
                return this.inputPaymentAmount * (this.inputFinanceTerm);
            } 
                
            console.log(this.selectedPaymentFrequencyId + ' is a frequency not a caught frequency');
            
        }
        
        return null;
    }

    get calculatedInterestRate() {
        return ( (this.totalPaymentAmount / this.totalPrice) - 1 );
    }

    get calculatedLoanProfit() {
        return (this.totalPaymentAmount - this.totalPrice);
    }

    get interestRateStyleClass() {

        if(this.calculatedInterestRate) {
            console.log('this.calculatedInterestRate');
            console.log(this.calculatedInterestRate);
            if(this.calculatedInterestRate >= 0.05) {
                return 'colorGreen';
            } else if(this.calculatedInterestRate > 0.0) {
                return 'colorOrange';
            } else if(this.calculatedInterestRate <= 0.0) {
                return 'colorRed';
            } 

            return null;
        }

        return null;
    }

    get errorDetected() {
        return false;
    }
}