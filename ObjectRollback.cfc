<cfcomponent output="false" mixin="model">

	<cffunction name="init">
		<cfset this.version = "1.1.3">
		<cfreturn this>
	</cffunction>

	<cffunction name="$resetToNew" returntype="void" access="public" output="false">
		<cfscript>
			var loc = {};
			
			// remove the persisted properties container
			StructDelete(variables, "$persistedProperties", false);
			// remove any primary keys set by the save
			for (loc.item in ListToArray(this.primaryKeys()))
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
							loc.array[loc.i].$resetToNew();
				}
			}
		</cfscript>
	</cffunction>

</cfcomponent>
