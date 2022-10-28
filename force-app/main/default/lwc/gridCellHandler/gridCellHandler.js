import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { reduceErrors, constants,quoteStatuses, offerRVType } from 'c/ldsUtils';
import FORM_FACTOR from '@salesforce/client/formFactor';
import findOfferDetailsOnChange from '@salesforce/apex/QuoteSetupController.findOfferDetailsOnChange';
import recordsSearch from '@salesforce/apex/QuoteSetupController.recordsSearch';
import Id from '@salesforce/user/Id';

// Cell to display below HTML components
const DISPLAY_MODE_CARDS = 'cards';
const DISPLAY_MODE_LWC_INPUT = 'lwc.input';
const DISPLAY_MODE_LOOKUP = 'lookup';
const DISPLAY_MODE_LWC_OUTPUT = 'lwc.output';
const DISPLAY_MODE_PICKLIST = 'picklist';
const DISPLAY_MODE_RADIO = 'radio';
const DISPLAY_MODE_CHECKBOX = 'checkbox';

// Import component templates
import cardTemplate from './cardTemplate.html';
import inputTemplate from './inputTemplate.html';
import lookupTemplate from './lookupTemplate.html';
import outputTemplate from './outputTemplate.html';
import picklistTemplate from './picklistTemplate.html';
import radioTemplate from './radioTemplate.html';
import checkboxTemplate from './checkboxTemplate.html';

const MAX_UNITS = 9999;
const MAX_UNIT_PRICE = 999999999;

/** This component can receive recods Array for various display components in row */
export default class GridCellHandler extends LightningElement {

    /**Variable declaration */
    labels = constants;
    quoteStatuses = quoteStatuses;
    offerRVType = offerRVType;

    @api notifyViaAlerts = false; // usable outside lightning context
    @api cellKey;
    @api cellMode; // cards, picklist, radio, lookup, lwc.input, lwc.output
    @api cellType; // apex, array, lwc comp datatype like number, datetime, file.. 
    @api cellIcon; 
    @api cellLabel = '';
    @api objectKey;
    @api recordTypeId;
    @api picklistFieldName;
    @api gridofferid = '';
    @api userlocale = '';
    @api tableName;
    @api disableSpecialTc;
    @api selectedUserId;
    currentUserId = Id;

    value; // derive from row
    label; // derive from row
    error; // handle error logic
    _recordTypeId;
    placeholder = this.labels.Search;
    options = [];
    @track otvalue;
    @track _gridRowData;
    @track _gridColumnMeta;
    curencycode;
    @track showUrlCol = false; //to show URL column
    @track endUrl = '';  
    radioLabel = '';
    radioValue = '';
    @track inputDisableFlag = false;
    @track _quoteStatus = '';
    @track lookupResult;
    isChecked = false;
    isCheckboxDisabled = false;
    disableFieldStages = [this.quoteStatuses.Approved,this.quoteStatuses.Expired,this.quoteStatuses.Declined,this.quoteStatuses.DocumentsGenerated,this.quoteStatuses.PendingESign,this.quoteStatuses.ReviewCompleted,this.quoteStatuses.PendingValidation,this.quoteStatuses.PendingDocumentation,this.quoteStatuses.PendingReview,this.quoteStatuses.PendingInformation,this.quoteStatuses.BlockedDueToMultiplePG];
    @api isDisabled;
    
    @api 
    get quoteStatus(){
        return this._quoteStatus;
    }

    /** Set quote status and check if the cell should be editable */
    set quoteStatus(value){
        this._quoteStatus = value;
        this.inputDisableFlag = false;
        
        if(this._quoteStatus != undefined && this.disableFieldStages.includes(this._quoteStatus)){    
            this.inputDisableFlag = true;
        }
    }

    @api 
    get gridColumnMeta(){
        return this._gridColumnMeta;
    }

    /** Set metadata for cell with array type (for picklists) */
    set gridColumnMeta(value){
        this.options = [];
        this._gridColumnMeta = value;
        
        for(let option1 in this._gridColumnMeta){           
            let optionLst = this._gridColumnMeta[option1];           
            const optionconst = {
                cellid: optionLst['cellid'],
                value: optionLst['value'],
                label: optionLst['label']
            }
            this.options.push(optionconst);          
        }       
        this.options = this.options.filter(res => res.cellid === ''+this.cellKey);
    }

    @api
    get gridRowData() {
        // populate input field for RV and Insurance value as soon as response is received
        if (this.cellKey === 'residualValue' || this.cellKey === 'insuranceAmount') {
            this.value = this._gridRowData[this.cellKey];
        }

        return this._gridRowData;
    }


    /** Get and set grid cell data according cell type and data */
    set gridRowData(value) {
        if (this.objectKey === "Insurance__c" && this.cellKey === 'insuranceCode' && this.cellMode === "lookup") {
            return;
        }  
        this._gridRowData = value;       
        this.value = this._gridRowData[this.cellKey];
        this.label = this.cellKey;
        
        if (this.isLookup()) {
            if (typeof(this._gridRowData['Offer__c']) != 'undefined' && typeof(this._gridRowData['Offer__c'] == 'string')){
                this.gridofferid = this._gridRowData['Offer__c'];
            }
            //if(this.value != undefined && this.value.length != 0){             
                let paramsForSearch = JSON.stringify({
                    selectedIds :   (this.value != undefined && this.value.length != 0) ? [this.value] : null,
                    objectKey:      this.objectKey,
                    tableName:      this.tableName,
                    behaveOnUserId: (this.selectedUserId) ? this.selectedUserId : this.currentUserId
                });
             
                recordsSearch({
                    paramsForSearch: paramsForSearch
                })
                .then((results) => {                 
                    this.error = undefined; 
                    if (results.length > 0) {
                        this.template.querySelector('c-lookup-search-panel').setSearchResults(results);
                        this.template.querySelector('c-lookup-search-panel').setLookupFieldOnLoad(results);
                    } else {
                        this.template.querySelector('c-lookup-search-panel').handleClearSelection(false);
                    }
                })
                .catch((error) => {
                    this.error = reduceErrors(error);
                    console.error(this.error);
                });
            //}
        }

        // if cell is radio
        if (this.isRadio()) {
            this.radioLabel = this._gridRowData[this.cellKey].label;
            this.radioValue = this._gridRowData[this.cellKey].value;
        }

        // if cell is simple output text
        if (this.isOutput()) {
            this.otvalue = this._gridRowData[this.cellKey];
        }

        /** add link to the opportunity name */
        if (this.cellKey == 'deal') {
            //this.endUrl = `${window.location.origin}/partners/s/quote?oppId=${this._gridRowData['dealid']}`;
            let linkVal = this._gridRowData[this.cellKey];
            this.endUrl = linkVal.substring(9, linkVal.indexOf('target')-2);
            this.otvalue = linkVal.substring(linkVal.indexOf('>')+1, linkVal.indexOf('</a>'));
            this.showUrlCol = true;           
        } 

        /** pecial terms & condition */
        if (this.cellKey == 'specialTncName') {
            this.otvalue = this._gridRowData['Name'];
        }

        if (this.cellKey == 'specialtncCheckbox' && this._gridRowData['Category'] == 'Mandatory') {
            this.isCheckboxDisabled = true;
            this.isChecked = true;
        } 
     
        if(this.disableSpecialTc && this.cellKey == 'specialtncCheckbox'){ //when document is generated
            this.isCheckboxDisabled = true;
       }

        /** set currency code */
        if (this._gridRowData.hasOwnProperty('curencycode')){
            this.curencycode = this._gridRowData['curencycode'];          
        }   
           
        /** set total price with currency code */
        /*if(this.cellKey == 'totalprice' && this.userlocale != '' && this.value != undefined && this.value.length != 0){  
            const userLocaleConst = typeof(this.userlocale) != 'undefined' && typeof(this.userlocale) == 'string' ? this.userlocale.replace('_','-') : 'en-US';           
            let totalPriceBeforeLocal = this._gridRowData[this.cellKey];            
            this.otvalue = new Intl.NumberFormat(userLocaleConst).format(totalPriceBeforeLocal); //to convert to user locale 
        } */
        
        if(this.cellKey == 'totalprice'  && this.value != undefined ){   
            const userLocaleConst = typeof(this.userlocale) != 'undefined' && this.userlocale != '' ? this.userlocale.replace('_','-') : 'en-US';           
            let totalPriceBeforeLocal = this._gridRowData[this.cellKey];            
            this.otvalue = new Intl.NumberFormat(userLocaleConst).format(totalPriceBeforeLocal); //to convert to user locale 
        }  
    }

    get maxValue() {
        if (this.cellKey === 'quantity') {
            return MAX_UNITS;
        } else if (this.cellKey === 'unitprice') {
            return MAX_UNIT_PRICE;
        }
    }

    get maxLength(){
        if (this.cellKey === 'specification') {
            return 43;
        }
    }

    connectedCallback() {
        switch (this.cellType.toLowerCase()) {
            // Data is provided by user
            case 'text': 
                break;
            case 'number': 
                break;
            case 'date': 
                break;
            case 'datetime': 
                break;
            case 'array': 
                if (this.isCards()) {
                    // Keep labels empty for cards since values === labels
                    this.options = this._gridColumnMeta.map((option, index) => ({
                        value: option.value,
                        iconName: option.icon,
                        cellid: option.cellid
                    }));
                } else {
                    this.options = this._gridColumnMeta.map((option, index) => ({
                        value: option.value,
                        label: option.label,
                        cellid: option.cellid
                    }));
                }
                this.options = this.options.filter(res => res.cellid === ''+this.cellKey);
                break;
            case 'apex': 
                if (this.objectKey === "Insurance__c" && this.cellKey === 'insuranceCode' && this.cellMode === "lookup") {
                    return;
                }
                if (this.isLookup()) {
                  
                    let paramsForSearch = JSON.stringify({
                        selectedIds :   (this.value != undefined && this.value.length != 0) ? [this.value] : null,
                        objectKey:      this.objectKey,
                        tableName:      this.tableName,
                        behaveOnUserId: (this.selectedUserId) ? this.selectedUserId : this.currentUserId
                    });

                    recordsSearch({
                        paramsForSearch: paramsForSearch
                    })
                    .then((results) => {
                        this.error = undefined;
                        this.template.querySelector('c-lookup-search-panel').setLookupFieldOnLoad(results);
                    })
                    .catch((error) => {
                        this.error = reduceErrors(error);
                        console.error(this.error);
                    });
                    
                } else {
                    this._recordTypeId = this.recordTypeId;
                }
                break;
            case 'file': 
                break;
            case 'url':                         
                break;
            case 'checkbox':                         
                break;
            default: {
                const errorMessage = `Invalid cell datatype for '${this.label}': ${this.cellType}`;
                console.error = errorMessage;
            }

            this.disableFields();
        }
        
        /** set total price with currency code */
        /*if(this.cellKey == 'totalprice' && this.userlocale != ''){  
            const userLocaleConst = typeof(this.userlocale) != 'undefined' && typeof(this.userlocale) == 'string' ? this.userlocale.replace('_','-') : 'en-US';           
            let totalPriceBeforeLocal = this._gridRowData[this.cellKey];
            this.otvalue = new Intl.NumberFormat(userLocaleConst).format(totalPriceBeforeLocal); //to convert to user locale 
        } */

        if(this.cellKey == 'totalprice'  && this.value != undefined ){   
            const userLocaleConst = typeof(this.userlocale) != 'undefined' && this.userlocale != '' ? this.userlocale.replace('_','-') : 'en-US';           
            let totalPriceBeforeLocal = this._gridRowData[this.cellKey];            
            this.otvalue = new Intl.NumberFormat(userLocaleConst).format(totalPriceBeforeLocal); //to convert to user locale 
        }

    }

    /** Select initial card value */
    renderedCallback() { 
        if (this.isCards() && this.value) {
            const selectedCardElement = this.template.querySelector(
                `[data-id="${this.value}"]`
            );
            if (selectedCardElement) {
                selectedCardElement.checked = true;
            }
        }

        this.disableFields();
    }

    /** Select the appropriate template for current display mode */
    render() {

        if ((this.cellKey === 'residualValue' && !this.gridRowData.isPurchaseOptionAvailable) 
            || (this.cellKey === 'insuranceAmount' && !this.gridRowData.isInsuranceAvailable)) {
            return outputTemplate;
        }
        
        switch (this.cellMode.toLowerCase()) {
            case DISPLAY_MODE_LWC_INPUT:
                return inputTemplate;
            
            case DISPLAY_MODE_LWC_OUTPUT:
                return outputTemplate;
             
            case DISPLAY_MODE_PICKLIST:
                return picklistTemplate;

            case DISPLAY_MODE_LOOKUP:
                return lookupTemplate;

            case DISPLAY_MODE_CARDS:
                return cardTemplate;

            case DISPLAY_MODE_RADIO:
                return radioTemplate;
            
            case DISPLAY_MODE_CHECKBOX:
                return checkboxTemplate;
            default:
                this.error = `Unsupported display mode for ${this.label}: ${this.cellMode}`;
                console.error(this.error);
        }
    }

    /** Get and set picklist value by field API name */
    @wire(getPicklistValues, {
        recordTypeId: '$_recordTypeId',
        fieldApiName: '$picklistFieldName' 
    })
    loadPicklistValues({ error, data }) {
        if (this.cellType === 'apex' && (this.isCards() || this.isRadio() || this.isPicklist())) {
            if (error) {
                this.error = reduceErrors(error);
                console.error(this.error);
            } else if (data) {
                this.error = undefined;
                // Load values from picklist field
                let options;
                if (this.isCards()) {
                    // Keep labels empty for cards since values === labels
                    options = data.values.map((option, index) => ({
                        value: option.value,
                        iconName: this.cellIcon
                    }));
                } else {
                    options = data.values.map((option, index) => ({
                        value: option.value,
                        label: option.label
                    }));
                }
                this.options = options;
            }
        }
    }

    /** When user press a key in the input field */
    keychange(event){       
        let charCode = event.keyCode;
         
        if (charCode == 45 && this.cellKey != 'specification'){ //we need to allow hyphen in specification field. for otherfields dont allow.
            event.preventDefault();
        }      
    }

    /**Called On offer change */
    handleOfferChange(offrId){      
        const offridconst = offrId.toString();
        findOfferDetailsOnChange({
            offeridstr : offridconst,
            applicableOfferId : '',
            accountId : '',
            isNewVersion : false,
            behaveOnUserId: (this.selectedUserId) ? this.selectedUserId : this.currentUserId
        })
        .then(result => {              
            const selectEvent = new CustomEvent('offerchange', {
                detail: result
            });
            this.dispatchEvent(selectEvent);
        })
        .catch(error => {
            this.error = error;
            this.data = undefined;
        }); 
    }

    /** Called on On change of a field value */
    handleChange(event) {
        if (this.objectKey === "Insurance__c" && this.cellKey === 'insuranceCode' && this.cellMode === "lookup") {
            return;
        }
        
        if (this.isCards() || this.isInput() || this.isOutput())
            this.value = event.target.value; // for card, input, output

        if (this.isRadio() || this.isPicklist()){
            //sends the selected value to the parent
            const selectRadioEvent = new CustomEvent('radiochange', {detail: event.target.value});
            this.dispatchEvent(selectRadioEvent); 
            this.value = event.detail.value; // for radio, picklist     
        }
      
        if (this.isLookup()) {
            this.value = event.detail.value;            
            const oldofferid = this._gridRowData['Offer__c'];
            //call only when the offer id is different and offer is changed
            if (this.cellKey == 'Offer__c' && event.detail.value != null && event.detail.value != '' && event.detail.value != oldofferid) {
                this.handleOfferChange(event.detail.value);
            }               
        }  

        if (this.cellKey == 'quantity' || this.cellKey == 'unitprice' || this.cellKey == 'Product' || this.cellKey == 'insuranceAmount' || this.cellKey == 'residualValue') {  
            let foundProduct;
            let changeval = this.value;
            if(this.cellKey == 'Product' ){
                changeval += '-' + event.detail.selectedName;                
                if(this.lookupResult != undefined)         
                    foundProduct = this.lookupResult.find(element => element.id == this.value);              
            }

            
            
            const changdcellkey = this.cellKey;
            const changdcelabel = this.cellLabel;
            const uid = this._gridRowData['uid'];
            const productType = this._gridRowData['productType'];
            const isProductAvailable = this._gridRowData['isProductAvailable'];
            
            //to hold the value of the lookup field on change
            const oldprodId = this._gridRowData['Product']; //get old product id of the cell
            if((this.cellKey == 'quantity' || this.cellKey == 'unitprice' || this.cellKey == 'insuranceAmount' || this.cellKey == 'residualValue') || (this.cellKey == 'Product' && this.value != oldprodId)){
                let detail = {
                    value : changeval, index: uid, changedcol : changdcellkey, 
                    changedlabel : changdcelabel , oldprodctId : oldprodId, 
                    tableName: this.tableName, productType: productType, isProductAvailable: isProductAvailable,
                    isItadApplicable : (this.cellKey == 'Product' && foundProduct != undefined ) ? foundProduct.isItadApplicable : false,
                    isPurchaseOptionAvailable: (this.cellKey == 'Product' && foundProduct != undefined ) ? foundProduct.isPurchaseOptionAvailable : null,
                    isInsuranceAvailable: (this.cellKey == 'Product' && foundProduct != undefined ) ? foundProduct.isInsuranceAvailable : null,
                };

                if (this.cellKey == 'Product' && this.value != oldprodId) {
                    detail.productType = event.detail.productType[0];
                }

                const selectEvent = new CustomEvent('inputchange', {
                    detail: detail
                });

                this.dispatchEvent(selectEvent);
            }          
        }

        //for calculation parameter table
        if(this.cellLabel == 'Term' || this.cellLabel == 'Frequency' || this.cellLabel == 'Interest' || this.cellLabel == 'ITAD' || this.cellLabel == this.offerRVType.Purchase_Option){
            const colData = {};  

            for (const ofrRow in this._gridRowData) {               
                if (this.cellKey === ofrRow) {
                    colData[ofrRow] = this.value;
                } else {
                    colData[ofrRow] = this._gridRowData[ofrRow];
                }
            }
            // dispatch event on change of any field to update the entire table json, will be used for save purpose
            const selectEvent = new CustomEvent('offerfieldchange', {
                detail: {colmData : colData, value: this.value}
            });
            this.dispatchEvent(selectEvent);
        } 
    }

    /** To update the json each time user leaves the specification field**/
    handleInputBlur(event){
        if (this.cellKey == 'specification') {
            const changeval = this.value;
            const changdcellkey = this.cellKey;
            const changdcelabel = this.cellLabel;
            const uid = this._gridRowData['uid'];
            const productType = this._gridRowData['productType'];
            if(this.value != undefined && this._gridRowData['Product'] != '' && this._gridRowData['Product'] != undefined){
                const selectEvent = new CustomEvent('inputchange', {
                    detail: {value : changeval, index: uid, changedcol : changdcellkey, changedlabel : changdcelabel, oldprodctId : '', tableName: this.tableName, productType: productType }
                });
                this.dispatchEvent(selectEvent);
            }         
        }
    }

    @api
    inputValue() {
       return { value : this.value, field: this.field };
    }

    /** Handle lookup search */
    searchLookupValues(event) {
        // Call Apex endpoint to search for records and pass results to the lookup
        if (this.cellType === 'apex') {
            let searchDetails = event.detail;
           
            let paramsForSearch = {
                searchTerm :    searchDetails['searchTerm'],
                selectedIds :   (searchDetails['selectedIds'] != undefined && searchDetails['selectedIds'].length > 0) ? searchDetails['selectedIds'] : null,
                objectKey:      searchDetails['objectKey'],
                tableName:      this.tableName,
                behaveOnUserId: (this.selectedUserId) ? this.selectedUserId : this.currentUserId
            };

            if (this.objectKey == 'Product2') {
                paramsForSearch.offerId = this.gridofferid;
            }

            recordsSearch({
                paramsForSearch: JSON.stringify(paramsForSearch)
            })
            .then((results) => {
                this.lookupResult = results;
                this.error = undefined;
                this.template.querySelector('c-lookup-search-panel').setSearchResults(results); 
            })
            .catch((error) => {
                this.error = reduceErrors(error);
                console.error(this.error);
            }); 
        } 
    }

    get columnClass() {
        // Force single column display for cards on mobile
        const isDualColumns =
            FORM_FACTOR === 'Small' ? false : this.numberOfColumns;
        return isDualColumns
            ? 'slds-col slds-size_1-of-2 slds-var-m-bottom_x-small'
            : 'slds-col slds-size_1-of-1 slds-var-m-bottom_x-small';
    }

    get hasIcons() {
        return true;
    }

    disableFields() {
        if (this.isDisabled) {    
            this.inputDisableFlag = true;
        }
    }

    // CHECK AND SET DISPLAY MODEL

    isCards() {
        return this.cellMode.toLowerCase() === DISPLAY_MODE_CARDS;
    }

    isLookup() {
        return this.cellMode.toLowerCase() === DISPLAY_MODE_LOOKUP;
    }

    isPicklist() {
        return this.cellMode.toLowerCase() === DISPLAY_MODE_PICKLIST;
    }

    isRadio() {
        return this.cellMode.toLowerCase() === DISPLAY_MODE_RADIO;
    }
    
    isInput() {
        return this.cellMode.toLowerCase() === DISPLAY_MODE_LWC_INPUT;
    }

    isOutput() {
        return this.cellMode.toLowerCase() === DISPLAY_MODE_LWC_OUTPUT;
    }

    isCheckbox() {
        return this.cellMode.toLowerCase() === DISPLAY_MODE_CHECKBOX;
    }
}