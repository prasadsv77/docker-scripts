define(function(require, exports, module) {
var __disableStrictMode__ = "use strict";

var _ = require('underscore');

var profileAttributeUtil = require("../../../../../model/util/profileAttributeUtil");

var clientValidationRegExpEnum = require("../../../../enum/clientValidationRegExpEnum");

var i18n = require("bundle!DomainDesignerBundle");

var i18nMessageUtil = require("runtime_dependencies/js-sdk/src/common/util/i18nMessage");

/*
 * Copyright (C) 2005 - 2020 TIBCO Software Inc. All rights reserved. Confidentiality & Proprietary.
 * Licensed pursuant to commercial TIBCO End User License Agreement.
 */
var i18nMessage = i18nMessageUtil.create(i18n);
var SELECT_KEYWORD = 'select';

var DerivedTablesDesignerDerivedTableValidator = function DerivedTablesDesignerDerivedTableValidator(options) {
  options = options || {};
  this.i18nMessage = options.i18nMessage ? options.i18nMessage : i18nMessage;
  this.domainSchemaSpecification = options.domainSchemaSpecification;
  this.domainSchemaGranularSpecs = options.domainSchemaGranularSpecs;
};

_.extend(DerivedTablesDesignerDerivedTableValidator.prototype, {
  validateQuery: function validateQuery(query) {
    if (!_.isString(query) || query === '') {
      return i18nMessage('domain.designer.derivedTables.createDerivedTables.dialog.input.query');
    }

    query = query.replace('\n', ' ');
    var WITH_KEYWORD = 'with';
    var queryWords = query.trim().split(/\s+/, 4),
        validationMessage,
        isContainsFourWorlds = queryWords.length >= 4,
        isStartWithSelect = queryWords[0].toLowerCase() === SELECT_KEYWORD || queryWords[0].toLowerCase() === WITH_KEYWORD,
        regexResult = query !== SELECT_KEYWORD && profileAttributeUtil.getProfileAttributes(query) || [],
        placeHolders = profileAttributeUtil.getProfileAttributePlaceHolders(query) || [],
        placeHoldersCount = placeHolders.length,
        arePlaceHoldersPresent = placeHoldersCount > 0,
        profileAttributesCount = regexResult.length,
        queryErrorMessage = i18nMessage('domain.designer.derivedTables.createDerivedTables.dialog.queryIsInvalid');

    if (!isContainsFourWorlds && !isStartWithSelect && arePlaceHoldersPresent) {
      if (profileAttributesCount !== placeHoldersCount) {
        validationMessage = queryErrorMessage;
      }
    } else if (!isContainsFourWorlds || !isStartWithSelect) {
      validationMessage = queryErrorMessage;
    }

    return validationMessage;
  },
  validateName: function validateName(name, tableId, dataSourceId) {
    var validationMessage, isNameUnique;

    if (!name || name && name.match(clientValidationRegExpEnum.RESOURCE_ID_BLACKLIST_REGEX_PATTERN)) {
      validationMessage = i18nMessage("domain.designer.derivedTables.createDerivedTables.dialog.nameIsInvalid", clientValidationRegExpEnum.RESOURCE_ID_BLACKLIST_SYMBOLS);
    } else {
      isNameUnique = this.domainSchemaSpecification.canRenameDerivedTable(tableId, name, dataSourceId);

      if (!isNameUnique) {
        validationMessage = i18nMessage('domain.designer.derivedTables.createDerivedTables.dialog.nameIsDuplicated');
      }
    }

    return validationMessage;
  },
  validateSelectedFields: function validateSelectedFields(selectedFields) {
    var validationMessage;

    if (_.keys(selectedFields).length < 1) {
      validationMessage = i18nMessage('domain.validation.selectedFields.not.selected');
    }

    return validationMessage;
  },
  validateFieldTypes: function validateFieldTypes(tableReferenceId, newFields) {
    var validationMessage;

    if (this.domainSchemaGranularSpecs.derivedTableFieldDataTypeCanNotBeChangedIfThereAreDependentFilters(tableReferenceId, newFields)) {
      validationMessage = i18nMessage('domain.designer.derivedTables.updateDerivedTables.fieldUsedInFilterExpression');
    }

    return validationMessage;
  }
});

module.exports = DerivedTablesDesignerDerivedTableValidator;

});