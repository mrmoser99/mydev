/************************************
 * 
 * 
 * Change Log:
 * 07/12/2022 - MRM made the state so that the user does not have to use the mouse; driving customers nuts
 * 11/19/2022 - Adam made a lot of changes in structure and overall functionality to improve the processing of more than 50 items in the picklist 
 */

 import { LightningElement, api, track } from 'lwc';
 import {ShowToastEvent} from 'lightning/platformShowToastEvent';
 
 /** The delay used when debouncing event handdlers before invoking functions. */
 const delay = 350; 
 const TOAST_TITLE_ERROR = 'Error Detected while Searching';
 
 export default class ReusableCustomDropdownWithSearch extends LightningElement {
 
     //functional properties
     @api fieldLabel;
     @api disabled = false;
     @track openDropDown = false;
     @track inputValue = "";
     @api placeholder = "";
     @api options;
     @track optionsToDisplay;
     @api defaultValue;
     delaytimeout;
     @track errorMessage;
 
 
     @api autoCompleteOff;
     @track scrollInner=false;
     blurCall=false;
     @api boldLabel;
     @api fieldRequiredOff;
     selectedState = 'none';
 
     @track loading = false;
      /** The size of the largest picklist that should be rendered on the browser to prevent blowing out the front end processing thousands of dynamically generated nodes. */
     @api displayBatchSize = 50;
     processedOptions = [];
     @track displayOptionsAreBeingTrimmed = false;
     numberOfNodesToRender = 50;
 
 
 
     connectedCallback() {
         console.log('value::'+this.defaultValue);
         
         if(this.defaultValue && this.defaultValue !== undefined) {

             if(this.options && this.options.length) {
                 console.log('Looking for a value of ' + this.defaultValue + ' in the list of ' + this.options.length + ' different available makes');
                 let tempArray = [...this.options];
                 let searchVal = this.defaultValue;
                 let selectedObj = tempArray.find(opt => opt.value === searchVal);
                 if(selectedObj) {
                     console.log('SUCCESS!! Located a value that matches the default value');
                     this.selectOptionObject(selectedObj.label, selectedObj.value);
                     console.log(selectedObj);
                 }
             } else {
                console.log('Passed a defaultvalue of ' + this.defaultValue + ' but no options');
             }
             // this.inputValue=this.defaultValue;
             // this.defaultValue=this.defaultValue;
         } else {
            console.log('Not passed a defaultValue');
         }
 
         if(this.boldLabel === 'false') {
             this.boldLabel=false;
         } else if(this.boldLabel === 'true') {
             this.boldLabel=true;
         } else {
             this.boldLabel=false;
         }
 
         if(this.fieldRequiredOff === 'false') {
             this.fieldRequiredOff=false;
         } else if(this.fieldRequiredOff === 'true') {
             this.fieldRequiredOff=true;
         } else {
             this.fieldRequiredOff=false;
         }
 
         if(this.displayBatchSize && this.displayBatchSize !== this.numberOfNodesToRender) { 
             this.numberOfNodesToRender = this.displayBatchSize;
         }
 
         if(this.options.length >= this.numberOfNodesToRender) {
             this.displayOptionsAreBeingTrimmed = true;
         }
 
     }
 
     renderedCallback() {
         if (this.openDropDown) {
             this.template.querySelectorAll('.search-input-class').forEach(inputElem => {
                 inputElem.focus();
             });
         }
     }
 
     //Public Method to set options and values
     // /@api setOptionsAndValues() {
     //     console.log('@api setOptionsAndValues() { is running');
     //     // Verify options is an array
     //     if(!this.options.length) return;
 
 
     //     let bufferArray = this.options.slice(0, this.numberOfNodesToRender);
 
     //     if (this.defaultValue && this.defaultValue !== "") {
     //         let selectedObj = this.getObjectByValue(this.defaultValue);
 
     //         if(selectedObj && typeof selectedObj !== 'undefined') {
     //             // this.label = selectedObj.label;
     //             // this.defaultValue = selectedObj.value;
     //             // this.setValues(selectedObj.value, selectedObj.label);
 
     //             // If the default value passed is already a part of the options displaying by default, move it to the top of the list instead of adding it 
     //             let defaultValuesIndex = bufferArray.findIndex(({displayObj}) => displayObj.value === selectedObj.value);
     //             if(defaultValuesIndex !== -1) {
     //                 bufferArray = bufferArray.splice(defaultValuesIndex, 1);
     //             } else {
     //                 console.log('Failed to locate an existing item in the subset that matches the default value');
     //                 console.log('Removing final element to be replaced with the located default value');
     //                 bufferArray = bufferArray.slice(0, -1);
     //             }
     //             this.optionsToDisplay = bufferArray;
     //         }
     //     } else {
     //         console.log('No default value passed, rendering default display Options');
     //     }
 
     //     if(this.displayBatchSize && this.displayBatchSize !== this.numberOfNodesToRender) { 
     //         this.numberOfNodesToRender = this.displayBatchSize;
     //     }
 
     //     if(this.options.length >= this.numberOfNodesToRender) {
     //         this.displayOptionsAreBeingTrimmed = true;
     //     }
 
     // }
 
     //Method to get Label for value provided
     getObjectByValue(val) {
         console.log('getObjectByValue value');
         console.log(val);
         let selectedObj = this.optionsToDisplay.find(({value}) => value === val);
 
         console.log(selectedObj);
         console.log('selectedObj');
 
         if (selectedObj) {
             console.log('selectedObj located in display values');
         } else {
             // Shouldnt use the processedOptions array here because we want to find the exact node that was passed based on the selected value 
             // The OG element may contain data that is valuable but was trimmed for efficient searching, we may also want an exact/non-manipulated match as a key for something upstream 
             selectedObj = this.options.find(({value}) => value === val);
             if(selectedObj) {
                 console.log(selectedObj);
                 console.log('selectedObj located in the MASTER options array');
             } else {
                 console.log('MAJOR ERROR: THIS SHOULLD NEVER RUN');
                 console.log('The user provided a value that was not referencable in either Array.');
             }
         }
 
         return selectedObj;
     }
 
     //Method to open listbox dropdown
     // openDropDown(event) {
     //     this.removeErrorBorder();
     //     this.dispatchEvent(new CustomEvent('change', { detail: '' }));
     //     this.toggleOpenDropDown(true);
     // }
 
     //Method to close listbox dropdown
     closeDropdown(event) {
         console.log('closeDropdown running');
         if(this.scrollInner===false) {
             
             if(this.inputValue === null || this.inputValue === ''  || this.inputValue === undefined) {
                 if(this.fieldRequiredOff===true) {
                     this.removeErrorBorder();
                 } else {
                     this.addErrorBorder();
                 }
                 // If there was a value and we are closing the dropdown with an empty searchbar, we can assume that we are removing the selection
                 // We need to bubble up that change from something to nothing
                 if(this.selectedValueExists) {
                     // this.setSelectedValueState(null);
                     this.clearSelectedObject();
                     this.triggerSelectionEvent();
                 } else {
                     console.log('Removed text from the searchbar before selecting any option, so nothing has changed from a data perspective')
                 }
                 // this.setSelectedValueState(null);
 
             } else {
                 console.log('The user triggered a close event while a input value existed')
                 if(this.selectedValueExists) {
                     // Because there is still a selected value that we are falling back to, we can ensure that the displayed text matches the pre-existing selection
                      
                     this.inputValue = this.selectedLabel;
                     // this.setSelectedValueState(this.selectedValue);
                     // Cannot do this check like this because it will hang the tab when options is large
     
                     // let check=0;
                     // for(let key in this.options){
                     //     if(this.options[key].value.toLowerCase()===this.inputValue.toLowerCase()){
                     //         console.log('key found in list of options');
                     //         break;
                     //     } else {
                     //         check=check+1;
                     //         console.log('check is now ' + check);
                     //     }
                     // }
                     // if(check===this.options.length) {
                     //     errorMsg=this.errorMessage;
                     //     this.addErrorBorder();
                 
                     // } else {
                     //     const detail = {};
                     //     detail.value = this.inputValue;
                     //     detail.label = this.inputValue;
                     //     this.dispatchEvent(new CustomEvent('change', { detail: detail }));
                     //     errorMsg='';
                     //     this.removeErrorBorder();
                     // }
                 } else {
                     console.log('The user removed focus after typing a partial search but still has not made a selection');
                     // for(let filteredOpt in this.optionsToDisplay){
                     //     if(filteredOpt.lowercaseLabel === lowercaseInputValue || filteredOpt.lowercaseValue === lowercaseInputValue) {
                     //         const detail = {};
                     //         detail.value = filteredOpt.value;
                     //         detail.label = filteredOpt.label;
                     //         this.dispatchEvent(new CustomEvent('change', { detail: detail }));
                     //         this.setSelectedValueState(filteredOpt.value);
                     //         break;
                     //     } else {
                     //         // Failed to locate a matching element in the 
                     //     }
                     // }
                     if(this.fieldRequiredOff===true) {
                         this.removeErrorBorder();
                     } else {
                         this.addErrorBorder();
                     }
     
     
                 }
             } 
             // if(errorMsg!=='') {
             //     this.toggleOpenDropDown(false);
             //     this.dispatchEvent(new CustomEvent('change', { detail: errorMsg }));
             // } 
 
             // What does this do?
             if (event.relatedTarget && event.relatedTarget.tagName === "UL" && event.relatedTarget.className.includes('customClass')) {
                 if (this.openDropDown) {
                     this.template.querySelectorAll('.search-input-class').forEach(inputElem => {
                         inputElem.focus();
                     });
                 }
             } else {
                 // window.setTimeout(() => {
                     this.toggleOpenDropDown(false);
                 // }, 300);
                 
             }
         } else {
             console.log('this.scrollInner is ' + this.scrollInner);
             console.log(event);
             this.scrollInner=false;
         }
     }
 
     //Method to handle readonly input click
     handleInputClick(event) {
         if(!this.processedOptions || this.processedOptions.length === 0) {
             this.loading = true;
             console.log('Havent processed options array yet');
             console.log(this.options);
 
             console.log(this.options.length);
             this.processOptionsArray();
 
             // setTimeout(() => {
             //     //filter dropdown list based on search key parameter
             //     this.processOptionsArray();
             // }, 0);

 
         } else {
             console.log('Already processed array');
         }
         // this.numberOfNodesToRender = DEFAULT_ACCEPTABLE_RENDER_LIST_SIZE;
         //this.resetParameters();
         this.removeErrorBorder();
         // this.dispatchEvent(new CustomEvent('change', { detail: '' }));
         if(this.selectedValue != null) {
             // this.setSelectedValueState(this.selectedValue);
             this.displayOptionsAreBeingTrimmed = false;
         }else if(this.inputValue === '' || this.inputValue === null || this.inputValue === undefined) {
             this.optionsToDisplay = this.processedOptions.slice(0, this.numberOfNodesToRender);
             this.displayOptionsAreBeingTrimmed = this.optionsToDisplay.length < this.processedOptions.length;
         } else {
             console.log('Input value exists so we show the current display options');
         }

         this.toggleOpenDropDown(true);
         
     }
 
 
     // By using a shallow copy of the passed array as the one to search through we achieve three primary benefits:
     // First, we are able manipluate/preprocess the data to normalize the data for later searching which saves iterations 
     // Second, the parent component may through heavy objects to the component, we can trim the fat for the most efficient looping possible
     // Third, becuse we are not reading from a public property, the engine can react (or not react) more intelligentlly and improve search speed
     processOptionsArray() {
 
         let processedOptionsArr = []
         this.options.forEach(opt => {
             processedOptionsArr.push(this.processOption(opt.label, opt.value));
         })
         
         console.log(processedOptionsArr);
         this.processedOptions = processedOptionsArr;
         this.loading = false;
     }
 
     processOption(label, value) {
         return{
             value: value,
             label: label,
             lowercaseValue: value.toLowerCase(),
             lowercaseLabel: label.toLowerCase()
         };
     }
 
     handleKeyEvent(component, event, helper) {
         // this.removeErrorBorder();
         // this.toggleOpenDropDown(true);
         // this.setSelectedValueState(null);
         
         // this.dispatchEvent(new CustomEvent('change', { detail: '' }));
     }
 
     //Method to handle key press on text input
     handleKeyPress(event) {
         this.removeErrorBorder();
         const searchKey = event.target.value;
         this.setInputValue(searchKey);
 
         // If there is already a search waiting, this implies that the user is actively typing 
         // Therefore, we cancel the queued job and accept the newest keystroke as their intended search param
         if (this.delaytimeout) {
             window.clearTimeout(this.delaytimeout);
         }
 
         // this.filterDropdownList(searchKey);
         this.loading = true;
 
         // Resets the dropdown rendered size if the user manipulates the text of the search param
         // This is because we are assuming that they are going to be providing specific strings that will significantly cut down on the size of the returned list
         // Therfore, we return to baseline rendered size so that they get a smaller,more targeted list back faster
         this.numberOfNodesToRender = this.displayBatchSize;
 
         // This setTimeout is needed to ensure that the UI can re-render with the this.loading true value 
         // Otherwise the loading would be true and we would immediately block rendring with the expensive operation
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
         if(!key || key === '') {
             this.optionsToDisplay = this.processedOptions.slice(0, this.numberOfNodesToRender);
         } else {
             console.log('filterDropdownList is running');
             // let filteredOptions = this.options.filter(item => item.label.toLowerCase().includes(key.toLowerCase()));
             // let filteredOptionsArray = [];
             const lowercaseKey = key.toLowerCase();
             // setTimeout(()=> {
                 this.filterOptions(lowercaseKey)
                 .then(res => {
                     console.log('filterDropdownList is finshed');
                     console.log(res);
                     this.optionsToDisplay = res;
                 })
                 .catch(err => {
                     const evt = new ShowToastEvent({
                         title:      TOAST_TITLE_ERROR,
                         message:    err.toString(),
                         variant:    'error',
                         duration:   10000
                     });
                     this.dispatchEvent(evt);
     
                 })
                 
             // }, 0);
             // Not sure what this is supposed to be doing... 
             // Appears to be ensuring an array lent
 
             // if (filteredOptions.length === 1){
                  
             //     filteredOptions.forEach(opt => {
             //         if (opt.value.length === 2) {
             //             this.selectedState = opt.value;
             //             // this.inputValue = opt.value;
             //             this.toggleOpenDropDown(false);
             //         }
             //     });
                 
             // }    
         }
         
         this.loading = false;

 
         // }
         // else{
         //     console.log('Failed to provide sufficient search data to render a comprehensible list of options');
         //     this.optionsToDisplay = [];
         //     this.selectedState = '';
         // }
 
 
     }
     // Promise that resolves with a truncated version of the optionsList based on the filter of the lowercase value breaking if the list is >= numberOfNodesToRender
     filterOptions(lowercaseKey) {
         console.log('Filtering by ' + lowercaseKey);
         return new Promise((resolve) => {
             let filteredOptionsArray = [];
             if(!this.processedOptions || this.processedOptions.length === 0) this.processOptionsArray();
 
             let optionsArrayToProcess = this.processedOptions;
             let len = optionsArrayToProcess.length;
         
             for(let i = 0; i < len; i++) {
                 let opt = optionsArrayToProcess[i];
                 if(opt.lowercaseLabel.includes(lowercaseKey)) {
                     filteredOptionsArray.push(opt);
                 } else {
                     // console.log('Couldnt find ' + key + ' in the options label of ' + opt.label);
                 }
                 if(filteredOptionsArray.length >= this.numberOfNodesToRender) {
                     this.displayOptionsAreBeingTrimmed = true;
                     break;
                 }
             }
             console.log(filteredOptionsArray.length);
             if(filteredOptionsArray.length < this.numberOfNodesToRender) {
                 this.displayOptionsAreBeingTrimmed = false;
             }
             // this.optionsToDisplay = filteredOptionsArray;
             resolve(filteredOptionsArray);
     
         })
     }
 
     //Method to handle selected options in listbox
     optionsClickHandler(event) {
         console.log('here');
         this.removeErrorBorder();
         const value = event.target.closest('li').dataset.value;
         const label = event.target.closest('li').dataset.label;
         this.selectOptionObject(label, value);
     }
 
     selectOptionObject(label, value) {
         this.inputValue = label;
         this.selectedObject = this.processOption(label, value);
         this.optionsToDisplay = [this.selectedObject];
         this.triggerSelectionEvent();
         this.toggleOpenDropDown(false);
 
     }
 
     displayMoreOptionsClickHandler(event) {
         console.log('displayMoreOptionsClickHandler was clicked');
         this.numberOfNodesToRender = this.numberOfNodesToRender + this.displayBatchSize;
         this.loading = true;
         // this.selectedValue = null;
         // This setTimeout is needed to ensure that the UI can re-render with the this.loading true value 
         // Otherwise the loading would be true and we would immediately block rendring with the expensive operation
         this.delaytimeout = setTimeout(() => {
             //filter dropdown list based on search key parameter
             this.filterDropdownList(this.inputValue);
         }, 0);
     
     }
     
 
     triggerSelectionEvent() {
         // console.log(detail);
         if(!this.selectedValueExists) {
             if(this.fieldRequiredOff) {
                 const detail = {};
                 detail.label = null;
                 detail.value = null;
                 this.dispatchEvent(new CustomEvent('change', {detail: detail}));
 
             } else {
                 const detail = 'Error Message Goes Here';
                 this.dispatchEvent(new CustomEvent('change', {detail: detail}));
             }
             
         } else {
            const detail = {};
            detail.label = this.selectedLabel;
            detail.value = this.selectedValue;
            console.log(detail);
            this.dispatchEvent(new CustomEvent('change', {detail: detail}));
         }
 
 
     }
 
     //Method to reset necessary properties
     // resetParameters() {
     //     this.setInputValue("");
     //     this.optionsToDisplay = this.options;
     // }
 
     //Method to set inputValue for search input box
     setInputValue(value) {
         this.inputValue = value;
     }
 
     clearSelectedObject() {
         this.inputValue = null;
         this.selectedObject = null;
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
         return (this.fieldLabel && this.fieldLabel !== "" ? "slds-form-element__label slds-show" : "slds-form-element__label slds-hide")
     }
 
     //getter setter for dropDownClass
     get dropDownClass() {
         return (this.openDropDown ? "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open" : "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click");
     }
 
     //getter setter for isValueSelected
     get isValueSelected() {
         return (this.label && this.label !== "" ? true : false);
     }
 
     get isDropdownOpen() {
         return (this.openDropDown ? true : false);
     }
 
     get isLoading() {
         return (this.loading ? true : false);
     }
 
     get selectedValue() {
         return (this.selectedObject && this.selectedObject.value != null ? this.selectedObject.value : null);
     }
 
     get selectedLabel() {
         return (this.selectedObject && this.selectedObject.label != null ? this.selectedObject.label : null);
     }
 
     get selectedValueExists() {
         return (this.selectedObject && this.selectedObject.value != null ? true : false);
     }
 
     get displayMoreOptionsAvailableMessage() {
         return (this.displayOptionsAreBeingTrimmed ? true : false);
     }
 
     get renderErrorMessage() {
         return (this.errorMessage != null ? true : false);
     }
 
 }