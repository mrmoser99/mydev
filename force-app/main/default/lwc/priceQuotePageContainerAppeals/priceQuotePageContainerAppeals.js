<!--
 - Author: Shiqi Sun, Traction on Demand
 - Date: 11/17/2021.
 -->

<!-- Price Quote Page Container -->
<template>
    <div class="slds-var-m-around_small">
        <div if:true={loading}>
            <lightning-spinner alternative-text="Loading..." variant="brand"></lightning-spinner>
        </div>
    </div>
    <div style="background-color: #FED8B1; padding: 5px; margin: 5px">
        This website is currently under construction. We may update the content of this website from time to time. We
        grant you access to this website as our valued partner for the sole purpose of obtaining your user experience
        feedback. This website contains confidential features of DLL business tools. Please do not share any content of
        this website with any third party without DLL’s prior express consent. The information presented on this Website
        is made available solely for demonstration and testing purposes. Please do not submit credit application via
        this website. DLL is not committed to financing any transaction you submit via this website. This website is
        provided on an “As Is” and “As Available” basis, DLL hereby disclaims any warranties. All feedback, comments,
        requests for technical support, and other communications relating to this website should be directed to Sophie
        McLachlan at smclachlan@leasedirect.com
    </div>
    <div if:true={displayModal}>
        <!-- Modal for when the cancel button is pressed and the user must confirm that the forum data is to be cleared-->
        <section role="dialog" tabindex="-1" aria-labelledby="modal-heading-01" aria-modal="true"
            aria-describedby="modal-content-id-1" class="slds-modal slds-fade-in-open">
            <div class="slds-modal__container">
                <header class="slds-modal__header">
                    <button class="slds-button slds-button_icon slds-modal__close slds-button_icon-inverse"
                        title="Close" onclick={displayModalToFalse}>
                        <lightning-icon icon-name="utility:close" alternative-text="close" variant="error" size="small">
                        </lightning-icon>
                        <span class="slds-assistive-text">Close</span>
                    </button>
                    <h2 id="modal-heading-01" class="slds-text-heading_medium slds-hyphenate">You are about to cancel
                        this quote</h2>
                </header>
                <div class="slds-modal__content slds-p-around_medium" id="modal-content-id-1">
                    <p>Do you want to save your changes? The latest changes have not been saved. Are you sure you would
                        like to cancel this quote?
                    </p>
                </div>
                <footer class="slds-modal__footer">
                    <button class="slds-button slds-button_neutral" onclick={displayModalToFalse}
                        title="Return to Page">No, stay on page</button>
                    <button class="slds-button slds-button_brand" onclick={handleCancel} title="Confirm Cancel">Yes,
                        cancel this quote</button>
                </footer>
            </div>
        </section>
        <div class="slds-backdrop slds-backdrop_open"></div>
    </div>
    <div if:true={displayModalDelete}>
        <!-- Modal for when the delete button is pressed and the user must confirm that the option is to be deleted-->
        <section role="dialog" tabindex="-1" aria-labelledby="modal-heading-02" aria-modal="true"
            aria-describedby="modal-content-id-2" class="slds-modal slds-fade-in-open">
            <div class="slds-modal__container">
                <header class="slds-modal__header">
                    <button class="slds-button slds-button_icon slds-modal__close slds-button_icon-inverse"
                        title="Close" onclick={displayModalDeleteToFalse}>
                        <lightning-icon icon-name="utility:close" alternative-text="close" variant="error" size="small">
                        </lightning-icon>
                        <span class="slds-assistive-text">Close</span>
                    </button>
                    <h2 id="modal-heading-02" class="slds-text-heading_medium slds-hyphenate">Are you sure that you want
                        to delete?</h2>
                </header>
                <div class="slds-modal__content slds-p-around_medium" id="modal-content-id-2">
                    <p>You are about to delete this record. If you clicked delete on accident, select no.
                    </p>
                </div>
                <footer class="slds-modal__footer">
                    <button class="slds-button slds-button_neutral" onclick={displayModalDeleteToFalse}
                        title="No">No</button>
                    <button class="slds-button slds-button_brand" onclick={handleDelete} title="Yes">Yes</button>
                </footer>
            </div>
        </section>
        <div class="slds-backdrop slds-backdrop_open"></div>
    </div>
    <lightning-layout multiple-rows=true horizontal-align="spread">

        <!-- header section -->
        <lightning-layout-item size=12 class="slds-box_border quote-header" if:true={specificationTabActive}>
            <div class="Header slds-p-around_medium">
                <lightning-layout>
                    <lightning-layout-item size=8>
                        <h1 class="slds-text-heading_large">
                            {sectionTitle}
                        </h1>
                        <span><b>Quote Number : </b>{quoteNumber}</span>
                        <!-- <a onclick={redirectToOpportunityPage}></a> -->
                    </lightning-layout-item>
                    <lightning-layout-item size=4>
                        <lightning-button class="slds-float_right" variant="brand-outline" disabled={hasQuotes}
                            label="Save" onclick={handleOnSaveOnlyHeader}></lightning-button>
                    </lightning-layout-item>
                </lightning-layout>
                <lightning-layout class="slds-p-around_medium" horizontal-align="space">
                    <lightning-layout-item padding="around-small" flexibility="auto">
                        <lightning-input name="nickname" label="Nickname" required=true value={nickname}
                            disabled={hasQuotes} onchange={onInputChange}>
                        </lightning-input>
                    </lightning-layout-item>
                    <lightning-layout-item padding="around-small" flexibility="auto">
                        <!--<c-lookup onsearch={handleSearch} label="Sales Rep (Click a Search Result)" required=true placeholder="Search Salesforce"
                                  disabled={hasQuotes} new-record-options={newContactRecord} onselectionchange={getSalesRepId}>
                        </c-lookup>-->
                        <!--<lightning-combobox name="salesRep" label="Sales Rep" value={salesRep}
                                            disabled={hasLocationSelectionSalesRep} options={salesRepList} onchange={handleChangeSalesRep}>
                        </lightning-combobox>-->
                        <template if:true={refreshSalesRepDropdown}>
                            <c-reusable-custom-dropdown-with-search-lwc bold-label="true"
                                error-message="Enter a valid sales rep" auto-complete-off="off" options={salesRepList}
                                field-required-off="true" value={salesRep} field-label="Sales Rep"
                                placeholder="Enter Sales Rep" onchange={handleChangeSalesRep}>
                            </c-reusable-custom-dropdown-with-search-lwc>
                        </template>
                        <template if:false={refreshSalesRepDropdown}>
                            <c-reusable-custom-dropdown-with-search-lwc bold-label="true"
                                error-message="Enter a valid sales rep" auto-complete-off="off" options={salesRepList}
                                field-required-off="true" value={salesRep} field-label="Sales Rep"
                                placeholder="Enter Sales Rep" onchange={handleChangeSalesRep}>
                            </c-reusable-custom-dropdown-with-search-lwc>
                        </template>
                    </lightning-layout-item>
                    <lightning-layout-item padding="around-small" flexibility="auto">
                        <template if:false={hasQuotes}>
                            <lightning-combobox name="location" label="Location" required=true value={location}
                                class="locationComboboxWidth" disabled={hasQuotes} options={siteList}
                                onchange={handleChangeLocation}>
                            </lightning-combobox>
                        </template>
                        <template if:true={hasQuotes}>
                            <lightning-combobox name="fakeLocation" label="Location" required=true
                                value={displayNameForLocation} class="locationComboboxWidth" disabled={hasQuotes}
                                options={displayNameForLocationPicklist}>
                            </lightning-combobox>
                        </template>
                    </lightning-layout-item>
                    <lightning-layout-item padding="around-small" flexibility="auto">
                        <lightning-combobox name="program" label="Program" required=true value={program}
                            disabled={hasLocationSelection} options={programPicklist}
                            onchange={handleDependentRatesPicklistChange}>
                        </lightning-combobox>
                    </lightning-layout-item>
                    <lightning-layout-item padding="around-small" flexibility="auto">
                        <lightning-combobox name="assetTypeQuote" label="Asset Condition" required=true
                            value={assetTypeQuote} options={assetTypeListQuote} onchange={handleChange}>
                        </lightning-combobox>
                    </lightning-layout-item>
                </lightning-layout>
            </div>
        </lightning-layout-item>
        <lightning-layout-item size=12 class="slds-box_border quote-header" if:false={specificationTabActive}>
            <div class="Header slds-p-around_medium">
                <lightning-layout>
                    <lightning-layout-item size=8>
                        <h1 class="slds-text-heading_large">
                            {sectionTitle}
                        </h1>
                        <span><b>Quote Number : </b>{quoteNumber}</span>
                        <!-- <a onclick={redirectToOpportunityPage}></a> -->
                    </lightning-layout-item>
                </lightning-layout>
                <lightning-layout class="slds-grid_align-spread" horizontal-align="space">
                    <lightning-layout-item padding="around-small" flexibility="auto">
                        <div class="display-field">
                            <label>Nickname</label>
                            <span>{nickname}</span>
                        </div>
                    </lightning-layout-item>
                    <lightning-layout-item padding="around-small" flexibility="auto">
                        <div class="display-field">
                            <label>Sales Rep</label>
                            <span>{salesRepDisplayName}</span>
                        </div>
                    </lightning-layout-item>
                    <lightning-layout-item padding="around-small" flexibility="auto">
                        <div class="display-field">
                            <label>Location</label>
                            <span>{displayLocation}</span>
                        </div>

                    </lightning-layout-item>
                    <lightning-layout-item padding="around-small" flexibility="auto">
                        <div class="display-field">
                            <label>Program</label>
                            <span>{displayProgram}</span>
                        </div>
                    </lightning-layout-item>
                    <lightning-layout-item padding="around-small" flexibility="auto">
                        <div class="display-field">
                            <label>Asset Condition</label>
                            <span>{assetTypeQuote}</span>
                        </div>
                    </lightning-layout-item>
                </lightning-layout>
            </div>
        </lightning-layout-item>

        <!-- tab view if has quotes -->
        <lightning-layout-item size=12 class="tab-class slds-box_border" if:true={hasQuotes}>
            <div>
                <lightning-tabset active-tab-value={currentTab}>
                    <lightning-tab onactive={handleTabChange} label="Specifications" class="tab-background"
                        value="spec">
                        <lightning-layout multiple-rows=true class="no-padding">
                            <!--Specification, Assets and Accessory-->
                            <lightning-layout-item size=8>
                                <div class="body-top slds-p-around_medium slds-m-right_medium">
                                    <lightning-layout multiple-rows=true>
                                        <lightning-layout-item size=12>
                                            <div class="specification-header">
                                                <h1 class="slds-text-heading_large">
                                                    <template if:false={showCreateInstead}>
                                                        <template if:false={quoteObject.isEdit}>
                                                            <template if:false={quoteObject.isClone}>
                                                                Specifications
                                                            </template>
                                                        </template>
                                                        <template if:true={quoteObject.isEdit}>
                                                            Edit this Quote Option
                                                        </template>
                                                        <template if:true={quoteObject.isClone}>
                                                            Copy this Quote Option
                                                        </template>
                                                    </template>
                                                    <template if:true={showCreateInstead}>
                                                        Create another Quote Option
                                                    </template>
                                                </h1>
                                                <p>Build your quote below then click 'Save'. You can select more than
                                                    one
                                                    financing term to view an instant comparison and generate multiple
                                                    options
                                                    based on
                                                    term</p>
                                                <p style="color:red">* fields are required</p>
                                            </div>
                                        </lightning-layout-item>
                                        <lightning-layout-item size=9></lightning-layout-item>
                                        <lightning-layout-item size=3>
                                            <lightning-combobox name="Option" label="Options" value={optionsPicklistVal}
                                                options={optionsPicklist} onchange={handleOptionPicklist}>
                                            </lightning-combobox>
                                        </lightning-layout-item>

                                        <!--Specifics sections-->

                                    </lightning-layout>
                                </div>
                            </lightning-layout-item>
                            <div>
                                <c-pricing-component oppid="00678000003eJ6mAAE">
                                </c-pricing-component>
                            </div>
                        </lightning-layout>
                    </lightning-tab>



                    <lightning-tab onactive={handleTabChange} label="Proposal" value="proposal">
                        <div class="proposal-container slds-p-around_medium">
                            <lightning-layout multiple-rows=true>
                                <lightning-layout-item size=12>
                                    <h2 class="slds-text-heading_medium marginBottom">Create Your Proposal</h2>
                                    <p class="marginBottomContent">Quickly generate a proposal by selecting the options
                                        you'd like to include and download your proposal document by clicking the
                                        buttons below.</p>
                                </lightning-layout-item>
                                <lightning-layout-item size=12>
                                    <template for:each={options} for:item="option">

                                        <c-quote-line-datatable key={option.quote.Id} options-sum={option.sumData}
                                            option={option} onselectquote={handleQuoteSelectForCreditApp}
                                            ontoggleproposalforquote={handleProposalToggleForQuote}
                                            oneditasset={handleAssetEdit} oncloneasset={handleAssetClone}
                                            ondeleteasset={handleAssetDelete}></c-quote-line-datatable>
                                    </template>

                                </lightning-layout-item>
                                <lightning-layout-item size="12">
                                    <lightning-button class="slds-m-right_small" variant="base" label="+ Add Option"
                                        title="+ Add Option" onclick={handleAddOption}></lightning-button>
                                </lightning-layout-item>
                                <lightning-layout-item size=12>
                                    <h2 class="slds-text-heading_medium">Comments for Your Customer</h2>
                                </lightning-layout-item>
                                <lightning-layout-item size="12">
                                    <lightning-textarea onchange={setCustomerComments} value={customerComments}
                                        placeholder="If there is anything else you would like to tell your customer, include it here. Helpful Example: Maintenance can be added for $100 per month."
                                        label=""></lightning-textarea>
                                </lightning-layout-item>
                                <lightning-layout-item size="12">
                                    <c-customer-quick-search oncustomerinfoshow={handleCustomerInfoShow}
                                        onprogressvaluechange={handleCreditAppRedirect} record-id={opportunityId}>
                                    </c-customer-quick-search>
                                </lightning-layout-item>

                                <!--Quote Proposal Document - Geetha- start-->
                                <lightning-layout-item size=12>
                                    <h2 class="slds-text-heading_medium marginBottom">Proposal Documents</h2>
                                    <p class="marginBottomContent">Select the option(s) you want to include in your
                                        proposal above and click to download.</p>
                                </lightning-layout-item>
                                <lightning-layout-item>
                                    <lightning-button class="slds-grid slds-p-top_small marginRight"
                                        variant="brand-outline" title="Download CustomerProposal"
                                        label="Download Dealer Proposal" value="CustomerProposal"
                                        sandbox="allow-downloads" onclick={handleDealerProposal}
                                        icon-name="utility:download">
                                    </lightning-button>
                                </lightning-layout-item>
                                <lightning-layout-item>
                                    <lightning-button class="slds-grid slds-p-top_small" variant="brand-outline"
                                        title="Download CustomerProposal" label="Download Customer Proposal"
                                        value="CustomerProposal" sandbox="allow-downloads"
                                        onclick={handleCustomerProposal} icon-name="utility:download">
                                    </lightning-button>
                                </lightning-layout-item>
                                <lightning-layout-item size=12>
                                    <p style="margin-top:10px;">Need an easy way to collect the correct information from
                                        a new customer? Here’s a credit application they can fill out. </p>
                                </lightning-layout-item>

                                <!--Quote Proposal Document - Geetha-end-->
                                <lightning-layout-item size="12">
                                    <!--<div class="body-bottom slds-p-around_medium slds-m-right_medium"> -->
                                    <lightning-button class="slds-float_right" variant="brand"
                                        disabled={hasNoActiveQuoteForCredApp} label="Continue to Credit Application"
                                        onclick={stampIsPrimaryOnSelectedOption}></lightning-button>
                                    <lightning-button class="slds-float_right slds-p-right_small" variant="brand"
                                        label="Save" onclick={saveCustomerComments}></lightning-button>
                                    <!--</div>-->
                                </lightning-layout-item>
                            </lightning-layout>
                        </div>

                    </lightning-tab>
                </lightning-tabset>
            </div>
        </lightning-layout-item>

        <!-- New Quote View (No quotes generated)-->
        <template if:false={hasQuotes}>
            <!--Specification, Assets and Accessory-->
            <lightning-layout-item size=8 class="slds-m-top_medium">
                <div class="body-top slds-p-around_medium slds-m-right_medium">
                    <lightning-layout multiple-rows=true>
                        <lightning-layout-item size=12>
                            <div class="specification-header">
                                <h1 class="slds-text-heading_large">
                                    <template if:false={showCreateInstead}>
                                        <template if:false={quoteObject.isEdit}>
                                            <template if:false={quoteObject.isClone}>
                                                Specifications
                                            </template>
                                        </template>
                                        <template if:true={quoteObject.isEdit}>
                                            Edit this Quote Option
                                        </template>
                                        <template if:true={quoteObject.isClone}>
                                            Copy this Quote Option
                                        </template>
                                    </template>
                                    <template if:true={showCreateInstead}>
                                        Create another Quote Option
                                    </template>
                                </h1>
                                <p>Build your quote below then click 'Save'. You can select more than one
                                    financing term to view an instant comparison and generate multiple options based on
                                    term</p>
                                <p style="color:red">* fields are required</p>
                            </div>
                        </lightning-layout-item>

                        <!--Specifics sections-->
                        <lightning-layout-item size=12>
                            <lightning-accordion allow-multiple-sections-open onsectiontoggle={handleSectionToggle}
                                class="slds-border_top slds-m-top_small" active-section-name={openAccordionSections}>
                                <!-- Finance section -->
                                <lightning-accordion-section name="Finance Structure" label="Finance Structure">
                                    <div class="financeBody">
                                        <lightning-layout multiple-rows>
                                            <lightning-layout-item size=6 class="slds-p-right_small">
                                                <lightning-combobox name="financeType" label="Lease Type"
                                                    value={financeType} options={financeTypePicklist}
                                                    disabled={isRateDisabled}
                                                    onchange={handleDependentRatesPicklistChange}
                                                    field-level-help="The header (see above) needs to be filled out to make a Lease Type selection."
                                                    required>
                                                </lightning-combobox>
                                            </lightning-layout-item>
                                            <lightning-layout-item size=6>
                                                <lightning-combobox name="financeTerm" label="Finance Term"
                                                    value={financeTerm} disabled={isFinanceTermDisabled}
                                                    options={financeTermPicklist} onchange={handleChange}
                                                    field-level-help="test" required>
                                                </lightning-combobox>
                                            </lightning-layout-item>
                                            <lightning-layout-item size=6 class="slds-p-right_small">
                                                <lightning-combobox name="rateType" label="Rate Type" value={rateType}
                                                    options={rateTypePicklist} disabled={isRateDisabled}
                                                    onchange={handleDependentTermsPicklistChange}
                                                    field-level-help="test" required>
                                                </lightning-combobox>
                                            </lightning-layout-item>
                                            <lightning-layout-item size=6>
                                                <lightning-combobox name="paymentFrequency" label="Payment Frequency"
                                                    value={paymentFrequency} options={frequencyPicklist}
                                                    onchange={handleChange} field-level-help="" required>
                                                </lightning-combobox>
                                            </lightning-layout-item>
                                            <lightning-layout-item size=6 class="slds-p-right_small">
                                                <lightning-combobox name="advPayments"
                                                    label="Advanced Payments (Optional)" value={advPayments}
                                                    options={advancedPaymentsPicklist} onchange={handleChange}
                                                    field-level-help="">
                                                </lightning-combobox>
                                            </lightning-layout-item>
                                        </lightning-layout>
                                    </div>

                                </lightning-accordion-section>

                                <!-- Assets section -->
                                <template if:false={isRateDisabled}>
                                    <template if:false={loading}>
                                        <template for:each={assets} for:item="assetItem">
                                            <lightning-accordion-section name={assetItem.sectionName}
                                                label={assetItem.assetHeading} key={assetItem.assetNo}>
                                                <c-assetcreation asset={assetItem} program-id={program}
                                                    quote-object={quoteObject} oncreateasset={handleAddAsset}
                                                    ondeleteasset={handleDeleteAssetModal}
                                                    onupdateasset={handleUpdateAsset}></c-assetcreation>
                                            </lightning-accordion-section>
                                        </template>
                                    </template>
                                </template>

                                <!-- Accessories Section -->
                                <template if:false={isRateDisabled}>
                                    <template if:false={loading}>
                                        <template for:each={accessories} for:item="accessoryItem">
                                            <lightning-accordion-section name={accessoryItem.accessoryHeading}
                                                label={accessoryItem.accessoryHeading} key={accessoryItem.accNo}>
                                                <c-accessorycreation accessory={accessoryItem}
                                                    related-asset-picklist={relatedAssets}
                                                    onupdateaccessory={handleUpdateAccessory}
                                                    oncreateaccessory={handleAddAccessory}
                                                    ondeleteaccessory={handleDeleteAccessoryModal}>
                                                </c-accessorycreation>
                                            </lightning-accordion-section>
                                        </template>
                                    </template>
                                </template>

                                <!-- Comment Section-->
                                <lightning-accordion-section name="Comments" label="Comments for DLL (Optional)">
                                    <div class="commentsBody">
                                        <lightning-layout multiple-rows=true>

                                            <lightning-layout-item size=12>
                                                <p>Please include any important comments about this quote option for
                                                    your
                                                    Account Manager</p>
                                            </lightning-layout-item>
                                            <lightning-layout-item size=12>
                                                <lightning-textarea data-id="createQuoteComments"
                                                    onchange={saveDLLComments} value={comments} label="Comments">
                                                </lightning-textarea>
                                            </lightning-layout-item>
                                        </lightning-layout>

                                    </div>
                                </lightning-accordion-section>
                            </lightning-accordion>
                        </lightning-layout-item>

                    </lightning-layout>
                </div>
            </lightning-layout-item>

            <!--Summary section-->
            <lightning-layout-item size="4" class="slds-m-top_medium">
                <div class="summary slds-p-around_medium">
                    <lightning-layout multiple-rows=true>
                        <lightning-layout-item class="slds-p-bottom_small" size=12>
                            <h1 class="slds-text-heading_large">
                                Summary
                            </h1>
                        </lightning-layout-item>
                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span class="slds-text-color_weak">Lease Type</span>
                        </lightning-layout-item>
                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span>{leaseTypeSummary}</span>
                        </lightning-layout-item>

                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span class="slds-text-color_weak">Rate Type</span>
                        </lightning-layout-item>
                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span>{rateTypeSummary}</span>
                        </lightning-layout-item>

                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span class="slds-text-color_weak">Advanced Payments</span>
                        </lightning-layout-item>
                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span>{advancedPaymentsSummary}</span>
                        </lightning-layout-item>

                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span class="slds-text-color_weak">Base Unit/Sales Price</span>
                        </lightning-layout-item>
                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span>{baseUnitSalesPriceWithoutDuplicatesSummary}</span>
                        </lightning-layout-item>

                        <hr />

                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span>Total Price</span>
                        </lightning-layout-item>
                        <lightning-layout-item class="slds-p-bottom_small" size="6" alignment-bump="right">
                            <span>{baseUnitSalesPriceSummary}</span>
                        </lightning-layout-item>
                        <lightning-layout-item class="slds-p-bottom_small" size=12>
                            <h1 class="slds-text-heading_large">
                                Payment
                            </h1>
                        </lightning-layout-item>

                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span class="slds-text-color_weak">Term</span>
                        </lightning-layout-item>
                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span>{termSummary}</span>
                        </lightning-layout-item>

                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span class="slds-text-color_weak">Interest Rate</span>
                        </lightning-layout-item>
                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span>{interestRateSummary}</span>
                        </lightning-layout-item>

                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span class="slds-text-color_weak">Residual</span>
                        </lightning-layout-item>
                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span>{residualSummary}</span>
                        </lightning-layout-item>

                        <hr />

                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span>Total Payment</span>
                        </lightning-layout-item>
                        <lightning-layout-item class="slds-p-bottom_small" size="6">
                            <span>{totalPaymentSummary}</span>
                        </lightning-layout-item>
                    </lightning-layout>
                </div>
            </lightning-layout-item>




            <!--Save and Close  This is the main save at the bottom of the quote page -->
            <lightning-layout-item size=8>
                <div class="body-bottom slds-p-around_medium slds-m-right_medium">
                    <lightning-button variant="brand-outline" label="Cancel" onclick={displayModalToTrue}>
                    </lightning-button>
                    <lightning-button class="slds-float_right" variant="brand" label="Save" onclick={handleOnSave}>
                    </lightning-button>
                </div>
            </lightning-layout-item>
        </template>


    </lightning-layout>



</template>