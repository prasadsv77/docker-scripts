define(["require","exports","module","underscore","../../../../../model/util/profileAttributeUtil","../../../../enum/clientValidationRegExpEnum","bundle!DomainDesignerBundle","runtime_dependencies/js-sdk/src/common/util/i18nMessage"],function(e,i,n){var a=e("underscore"),t=e("../../../../../model/util/profileAttributeUtil"),r=e("../../../../enum/clientValidationRegExpEnum"),d=e("bundle!DomainDesignerBundle"),s=e("runtime_dependencies/js-sdk/src/common/util/i18nMessage"),l=s.create(d),o=function(e){e=e||{},this.i18nMessage=e.i18nMessage?e.i18nMessage:l,this.domainSchemaSpecification=e.domainSchemaSpecification,this.domainSchemaGranularSpecs=e.domainSchemaGranularSpecs};a.extend(o.prototype,{validateQuery:function(e){if(!a.isString(e)||""===e)return l("domain.designer.derivedTables.createDerivedTables.dialog.input.query");e=e.replace("\n"," ");var i,n=e.trim().split(/\s+/,4),r=n.length>=4,d="select"===n[0].toLowerCase()||"with"===n[0].toLowerCase(),s="select"!==e&&t.getProfileAttributes(e)||[],o=t.getProfileAttributePlaceHolders(e)||[],c=o.length,u=c>0,m=s.length,g=l("domain.designer.derivedTables.createDerivedTables.dialog.queryIsInvalid");return r||d||!u?r&&d||(i=g):m!==c&&(i=g),i},validateName:function(e,i,n){var a;return!e||e&&e.match(r.RESOURCE_ID_BLACKLIST_REGEX_PATTERN)?a=l("domain.designer.derivedTables.createDerivedTables.dialog.nameIsInvalid",r.RESOURCE_ID_BLACKLIST_SYMBOLS):this.domainSchemaSpecification.canRenameDerivedTable(i,e,n)||(a=l("domain.designer.derivedTables.createDerivedTables.dialog.nameIsDuplicated")),a},validateSelectedFields:function(e){var i;return a.keys(e).length<1&&(i=l("domain.validation.selectedFields.not.selected")),i},validateFieldTypes:function(e,i){var n;return this.domainSchemaGranularSpecs.derivedTableFieldDataTypeCanNotBeChangedIfThereAreDependentFilters(e,i)&&(n=l("domain.designer.derivedTables.updateDerivedTables.fieldUsedInFilterExpression")),n}}),n.exports=o});