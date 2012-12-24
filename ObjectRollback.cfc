<cfcomponent output="false" mixin="model">

	<cffunction name="init">
		<cfset this.version = "1.1.3,1.1.8">
		<cfreturn this>
	</cffunction>
	
	<cffunction name="nestedProperties" output="false" access="public" returntype="void">
		<cfargument name="association" type="string" required="false" default="" hint="The association (or list of associations) you want to allow to be set through the params. This argument is also aliased as `associations`." />
		<cfargument name="autoSave" type="boolean" required="false" hint="Whether to save the association(s) when the parent object is saved." />
		<cfargument name="allowDelete" type="boolean" required="false" hint="Set `allowDelete` to `true` to tell Wheels to look for the property `_delete` in your model. If present and set to a value that evaluates to `true`, the model will be deleted when saving the parent." />
		<cfargument name="sortProperty" type="string" required="false" hint="Set `sortProperty` to a property on the object that you would like to sort by. The property should be numeric, should start with 1, and should be consecutive. Only valid with `hasMany` associations." />
		<cfargument name="rejectIfBlank" type="string" required="false" hint="A list of properties that should not be blank. If any of the properties are blank, any CRUD operations will be rejected." />
		<cfargument name="rollbackKeys" type="string" required="false" default="" hint="A list of the primary keys to rollback if a save fails." />
		<cfscript>
			var loc = {};
			$args(args=arguments, name="nestedProperties", combine="association/associations");
			arguments.association = $listClean(arguments.association);
			loc.iEnd = ListLen(arguments.association);
			for (loc.i = 1; loc.i lte loc.iEnd; loc.i++)
			{
				loc.association = ListGetAt(arguments.association, loc.i);
				if (StructKeyExists(variables.wheels.class.associations, loc.association))
				{
					variables.wheels.class.associations[loc.association].nested.allow = true;
					variables.wheels.class.associations[loc.association].nested.delete = arguments.allowDelete;
					variables.wheels.class.associations[loc.association].nested.autoSave = arguments.autoSave;
					variables.wheels.class.associations[loc.association].nested.sortProperty = arguments.sortProperty;
					variables.wheels.class.associations[loc.association].nested.rollbackKeys = $listClean(arguments.rollbackKeys);
					variables.wheels.class.associations[loc.association].nested.rejectIfBlank = $listClean(arguments.rejectIfBlank);
					// add to the white list if it exists
					if (StructKeyExists(variables.wheels.class.accessibleProperties, "whiteList"))
						variables.wheels.class.accessibleProperties.whiteList = ListAppend(variables.wheels.class.accessibleProperties.whiteList, loc.association, ",");
				}
				else if (application.wheels.showErrorInformation)
				{
					$throw(type="Wheels.AssociationNotFound", message="The `#loc.association#` assocation was not found on the #variables.wheels.class.modelName# model.", extendedInfo="Make sure you have called `hasMany()`, `hasOne()`, or `belongsTo()` before calling the `nestedProperties()` method.");
				}
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="persistedOnInitialization" access="public" output="false" returntype="boolean">
		<cfscript>
			if (StructKeyExists(variables.wheels.instance, "persistedOnInitialization") && variables.wheels.instance.persistedOnInitialization)
				return true;
		</cfscript>
		<cfreturn false />
	</cffunction>
	
	<cffunction name="setPersistedOnInitialization" access="public" output="false" returntype="void">
		<cfargument name="persisted" type="boolean" required="true" />
		<cfset variables.wheels.instance.persistedOnInitialization = arguments.persisted />
	</cffunction>

	<cffunction name="$resetToNew" returntype="void" access="public" output="true">
		<cfargument name="primaryKeys" type="string" required="false" />
		<cfscript>
			var loc = {};
			
			if (persistedOnInitialization())
				return;
			
			arguments.primaryKeys = (Len(arguments.primaryKeys)) ? arguments.primaryKeys : this.primaryKeys();
			
			// remove the persisted properties container
			StructDelete(variables, "$persistedProperties", false);
			// remove any primary keys set by the save
			for (loc.item in ListToArray(arguments.primaryKeys))
				StructDelete(this, loc.item, false);
		</cfscript>
	</cffunction>
	
	<cffunction name="$saveAssociations" returntype="boolean" access="public" output="false">
		<cfargument name="parameterize" type="any" required="true" />
		<cfargument name="reload" type="boolean" required="true" />
		<cfargument name="validate" type="boolean" required="true" />
		<cfargument name="callbacks" type="boolean" required="true" />
		<cfscript>
			var loc = {};
			var coreSaveAssociations = core.$saveAssociations;
			loc.returnValue = coreSaveAssociations(argumentCollection=arguments);
			
			// if the associations were not saved correctly, roll them back to their new state but keep the errors
			if (!loc.returnValue) $resetAssociationsToNew();
		</cfscript>
		<cfreturn loc.returnValue />
	</cffunction>
	
	<cffunction name="$resetAssociationsToNew" returntype="void" access="public" output="false">
		<cfscript>
			var loc = {};
			loc.associations = variables.wheels.class.associations;
			for (loc.association in loc.associations)
			{
				if (loc.associations[loc.association].nested.allow && loc.associations[loc.association].nested.autoSave && StructKeyExists(this, loc.association))
				{
					loc.array = this[loc.association];
	
					if (IsObject(this[loc.association]))
						loc.array = [ this[loc.association] ];
	
					if (IsArray(loc.array))
						for (loc.i = 1; loc.i lte ArrayLen(loc.array); loc.i++)
							loc.array[loc.i].$resetToNew(primaryKeys=loc.associations[loc.association].nested.rollbackKeys);
				}
			}
		</cfscript>
	</cffunction>
	
	<cffunction name="$createInstance" returntype="any" access="public" output="false">
		<cfargument name="properties" type="struct" required="true">
		<cfargument name="persisted" type="boolean" required="true">
		<cfargument name="row" type="numeric" required="false" default="1">
		<cfargument name="base" type="boolean" required="false" default="true">
		<cfargument name="callbacks" type="boolean" required="false" default="true" hint="See documentation for @save.">
		<cfscript>
			var loc = {};
			var coreCreateInstance = core.$createInstance;
			loc.returnValue = coreCreateInstance(argumentCollection=arguments);
			loc.returnValue.setPersistedOnInitialization(arguments.persisted);
		</cfscript>
		<cfreturn loc.returnValue />
	</cffunction>	

</cfcomponent>
