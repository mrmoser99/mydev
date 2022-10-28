/************************************
 * 
 * 
 * Change Log:
 * 07/12/2022 - MRM made the state so that the user does not have to use the mouse; driving customers nuts
 */

import { LightningElement, api, track } from 'lwc';

/** The delay used when debouncing event handdlers before invoking functions. */
const delay = 350;
export default class ReusableCustomDropdownWithSearchLwc extends LightningElement {

    //functional properties
    @api fieldLabel;
    @api disabled = false;
    @track openDropDown = false;
    @api inputValue = "";
    @api placeholder = "";
    @api options;
    @track optionsToDisplay;
    @api value = "";
    @track label = "";
    delaytimeout;
    @api errorMessage;
    @api autoCompleteOff;
    @track scrollInner=false;
    blurCall=false;
    @api boldLabel ;
    @api fieldRequiredOff;
    selectedState = 'none';
    //constructor
    constructor() {
        super();
    }

    @api 
    reset(){
        this.value = '';
        this.connectedCallback();
    }

    connectedCallback() {
        console.log('inputValue::'+this.value);
        if(this.value!=undefined) {
            this.inputValue=this.value;
        }
        if(this.boldLabel=='false') {
            this.boldLabel=false;
        } else if(this.boldLabel=='true') {
            this.boldLabel=true;
        } else {
            this.boldLabel=false;
        }

        if(this.fieldRequiredOff=='false') {
            this.fieldRequiredOff=false;
        } else if(this.fieldRequiredOff=='true') {
            this.fieldRequiredOff=true;
        } else {
            this.fieldRequiredOff=false;
        }
        this.setOptionsAndValues();
    }

    renderedCallback() {
        if (this.openDropDown) {
            this.template.querySelectorAll('.search-input-class').forEach(inputElem => {
                inputElem.focus();
            });
        }
    }

    //Public Method to set options and values
    @api setOptionsAndValues() {
        this.optionsToDisplay = (this.options && this.options.length > 0 ? this.options : []);
        if (this.inputValue && this.inputValue != "") {
            let label = this.getLabel(this.inputValue);
            if (label && label != "") {
                this.label = label;
            }
        }
        else {
            this.label = "";
        }
    }

    //Method to get Label for value provided
    getLabel(value) {
        let selectedObjArray = this.options.filter(obj => obj.value === value);
        if (selectedObjArray && selectedObjArray.length > 0) {
            return selectedObjArray[0].label;
        }
        return null;
    }

    //Method to open listbox dropdown
    openDropDown(event) {
        this.removeErrorBorder();
        this.dispatchEvent(new CustomEvent('change', { detail: '' }));
        this.toggleOpenDropDown(true);
    }

    //Method to close listbox dropdown
    closeDropdown(event) {
        if(this.scrollInner==false) {
            var errorMsg;
            if(this.inputValue==null || this.inputValue=='' || this.inputValue==undefined) {
                if(this.fieldRequiredOff==true) {
                    errorMsg='';
                    this.removeErrorBorder();
                } else {
                    errorMsg='Complete this field.';
                    this.addErrorBorder();
                }
                
            } else {
                var check=0;
                for(var key in this.options){
                    if(this.options[key].value.toLowerCase()==this.inputValue.toLowerCase()){
                        break;
                    } else {
                        check=check+1;
                    }
                }
                if(check==this.options.length) {
                    errorMsg=this.errorMessage;
                    this.addErrorBorder();
            
                } else {
                    const detail = {};
                    detail["value"] = this.inputValue;
                    detail["label"] = this.inputValue;
                    this.dispatchEvent(new CustomEvent('change', { detail: detail }));
                    errorMsg='';
                    this.removeErrorBorder();
                }
            }
            if(errorMsg!='') {
                this.toggleOpenDropDown(false);
                this.dispatchEvent(new CustomEvent('change', { detail: errorMsg }));
            } 
            if (event.relatedTarget && event.relatedTarget.tagName == "UL" && event.relatedTarget.className.includes('customClass')) {
                if (this.openDropDown) {
                    this.template.querySelectorAll('.search-input-class').forEach(inputElem => {
                        inputElem.focus();
                    });
                }
            }
            else {
                window.setTimeout(() => {
                    this.toggleOpenDropDown(false);
                }, 300);
            }
        }
    }

    //Method to handle readonly input click
    handleInputClick(event) {
        //this.resetParameters();
        this.removeErrorBorder();
        this.dispatchEvent(new CustomEvent('change', { detail: '' }));
        if(this.inputValue=='' || this.inputValue==null || this.inputValue==undefined) {
            this.optionsToDisplay = this.options;
        } else if(this.inputValue) {
            this.filterDropdownList(this.inputValue);
        
        }
        this.toggleOpenDropDown(true);
        
    }
    

    //Method to handle key press on text input
    handleKeyPress(event) {
        this.removeErrorBorder();
        const searchKey = event.target.value;
        this.setInputValue(searchKey);
        if (this.delaytimeout) {
            window.clearTimeout(this.delaytimeout);
        }

        this.delaytimeout = setTimeout(() => {
            //filter dropdown list based on search key parameter
            this.filterDropdownList(searchKey);
        }, delay);
    }

    mouseOutMethod(event) {
        this.scrollInner=false;
    }
    mouseOverMethod(event) {
        this.scrollInner=true;
    }

    //Method to filter dropdown list
    filterDropdownList(key) {

        const filteredOptions = this.options.filter(item => item.label.toLowerCase().includes(key.toLowerCase()));
        this.optionsToDisplay = filteredOptions;
        
        if (filteredOptions.length == 1){
             
            filteredOptions.forEach(key => {
                if (key.value.length === 2) {
                    this.selectedState = key.value;
                    this.inputValue = key.value;
                    this.toggleOpenDropDown(false);
                }
            });         
            
        }
        else{
            this.selectedState = '';
        }
         
        
         
             
    }

    //Method to handle selected options in listbox
    optionsClickHandler(event) {
        console.log('here');
        this.removeErrorBorder();
        const value = event.target.closest('li').dataset.value;
        const label = event.target.closest('li').dataset.label;
        this.inputValue=label;
        this.setValues(value, label);
        this.toggleOpenDropDown(false);
        const detail = {};
        detail["value"] = value;
        detail["label"] = label;
        this.dispatchEvent(new CustomEvent('change', { detail: detail }));
    }

    //Method to reset necessary properties
    resetParameters() {
        this.setInputValue("");
        this.optionsToDisplay = this.options;
    }

    //Method to set inputValue for search input box
    setInputValue(value) {
        this.inputValue = value;
    }

    //Method to set label and value based on
    //the parameter provided
    setValues(value, label) {
        this.label = label;
        this.value = value;
    }

    handleKeyEvent(component, event, helper) {
        this.removeErrorBorder();
        this.toggleOpenDropDown(true);
        this.dispatchEvent(new CustomEvent('change', { detail: '' }));
    }
    //Method to toggle openDropDown state
    @api 
    toggleOpenDropDown(toggleState) {
        this.openDropDown = toggleState;
    }

    @api
    addErrorBorder(){
        this.template.querySelector('[data-id="divblock"]').className='borderClass';
    }

    @api
    removeErrorBorder(){
        this.template.querySelector('[data-id="divblock"]').className='borderClassRemove';
    }

    //getter setter for labelClass
    get labelClass() {
        return (this.fieldLabel && this.fieldLabel != "" ? "slds-form-element__label slds-show" : "slds-form-element__label slds-hide")
    }

    //getter setter for dropDownClass
    get dropDownClass() {
        return (this.openDropDown ? "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open" : "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click");
    }

    //getter setter for isValueSelected
    get isValueSelected() {
        return (this.label && this.label != "" ? true : false);
    }

    get isDropdownOpen() {
        return (this.openDropDown ? true : false);
    }


}