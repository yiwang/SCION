<?xml version="1.0"?>
<stylesheet 
	xmlns="http://www.w3.org/1999/XSL/Transform" 
	xmlns:s="http://www.w3.org/2005/07/scxml"
	version="1.0">
	<output method="text"/>

	<param name="wrapScriptInFunction" select="false()"/>
	<param name="wrapExprInFunction" select="false()"/>
	<param name="wrapCondInFunction" select="false()"/>

	<!-- wrappers -->
	<param name="JSONPCallbackName" select="false()"/>
	<param name="wrapInAnonymousFunction" select="false()"/>
	<param name="wrapInAsyncModuleDefinition" select="false()"/>

	<!-- extra stuff we can add in to allow some possible optimizations at runtime -->
	<param name="genDepth" select="false()"/>
	<param name="genAncestors" select="false()"/>

	<!-- constants -->
	<variable name="basic-kind" select="0"/>
	<variable name="composite-kind" select="1"/>
	<variable name="parallel-kind" select="2"/>
	<variable name="history-kind" select="4"/>
	<variable name="initial-kind" select="5"/>
	<variable name="final-kind" select="6"/>

	<template match="/">
		<choose>
			<when test="$JSONPCallbackName">
				<value-of select="$JSONPCallbackName"/>(
					<call-template name="genRoot"/>
				)
			</when>
			<when test="$wrapInAnonymousFunction">
				(function(){
					<call-template name="genRoot"/>
				}).apply(this,arguments)
			</when>
			<when test="$wrapInAsyncModuleDefinition">
				define(
					<call-template name="genRoot"/>
				)
			</when>
			<otherwise>
				<call-template name="genRoot"/>
			</otherwise>
		</choose>
	</template>

	<template name="genRoot">
		<!-- context here is / -->
		{
			"states" : [
				<for-each select=".//s:scxml | .//s:state | .//s:parallel | .//s:history | .//s:final | .//s:initial">
					<apply-templates select="."/>
					<if test="not(position() = last())">,</if>
				</for-each>
			],
			"transitions" : [
				<for-each select=".//s:transition">
					<apply-templates select="."/>
					<if test="not(position() = last())">,</if>
				</for-each>
			],
			"root" : <call-template name="genId">
					<with-param name="s" select="s:scxml"/>
				 </call-template>,
			"profile" : "<value-of select="s:scxml/@profile"/>",
			"scripts" : [<apply-templates select="s:script"/>],
			"events" : <call-template name="genEventsEnum"/>
		}
	</template>

	<template name="genInitial">
		<param name="s" select="."/>

		<choose>
			<when test="$s/@initial">
				"<value-of select="$s/@initial"/>"
			</when>
			<otherwise>
				<call-template name="genId">
					<with-param name="s" select="$s/s:initial"/>
				</call-template>
			</otherwise>
		</choose>
	</template>

	<template match="s:scxml | s:state | s:parallel | s:history | s:final | s:initial">

		<variable name="stateNum">
			<number level="any" count="s:scxml | s:state | s:parallel | s:history | s:final | s:initial"/>
		</variable>

		<variable name="basicStateNum">
			<number level="any" count="s:*[self::s:state | self::s:history | self::s:final | self::s:initial][not (s:state | s:parallel | s:history | s:final | s:initial)]"/>
		</variable>

		<!-- select kind -->
		<variable name="kind">
			<choose>
				<when test="self::s:state and (s:scxml | s:state | s:parallel | s:history | s:final | s:initial)">
					<value-of select="$composite-kind"/>
							
				</when>
				<when test="self::s:state and not (s:state | s:parallel | s:history | s:final | s:initial)">
					<value-of select="$basic-kind"/>
							
				</when>
				<when test="self::s:scxml">
					<value-of select="$composite-kind"/>
				</when>
				<when test="self::s:initial">
					<value-of select="$initial-kind"/>
				</when>
				<when test="self::s:parallel">
					<value-of select="$parallel-kind"/>
				</when>
				<when test="self::s:final">
					<value-of select="$final-kind"/>
				</when>
				<when test="self::s:history">
					<value-of select="$history-kind"/>
				</when>
				<otherwise>
				</otherwise>
			</choose>
		</variable>

		{
			<if test="s:history">
				"history" : 	"<value-of select="s:history/@id"/>",
			</if>
			<if test="self::s:history">
				"isDeep" : <value-of select="@type = 'deep'"/>,
			</if>
			<if test="s:initial">
				"initial" : 	<call-template name="genInitial"/>,
			</if>
			"onexit" : 	[<for-each select="s:onexit/*">
						<apply-templates select="."/>
						<if test="not(position() = last())">,</if>
					</for-each>],
			"onentry" : 	[<for-each select="s:onentry/*">
						<apply-templates select="."/>
						<if test="not(position() = last())">,</if>
					</for-each>],
			"transitions" : [<for-each select="s:transition">
						<variable name="transitionNum">
							<number level="any" count="s:transition"/>
						</variable>
						<value-of select="$transitionNum - 1"/>
						<if test="not(position() = last())">,</if>
					</for-each>],
			<if test="not(self::s:scxml)">
			"parent" : 	<call-template name="genId">
						<with-param name="s" select=".."/>
					</call-template>,
			</if>
			"id" : 		<call-template name="genId"/>,
			<if test="$genAncestors">
				"ancestors" : [<for-each select="ancestor::*">
							<sort select="position()" data-type="number" order="descending"/>	
							<call-template name="genId"/>
							<if test="not(position() = last())">,</if>
						</for-each>],
			</if>
			<if test="$genDepth">
				"depth" : <value-of select="count(ancestor::*)"/>,
			</if>
			"documentOrder" : <value-of select="$stateNum - 1"/>,
			<if test="$kind = $basic-kind or $kind = $initial-kind or $kind = $history-kind">
			"basicDocumentOrder" : <value-of select="$basicStateNum - 1"/>,
			</if>
			"children" : [<for-each select="s:state | s:parallel | s:final | s:history | s:initial">
						<call-template name="genId"/>
						<if test="not(position() = last())">,</if>
					</for-each>],
			"kind" : <value-of select="$kind"/>

		}
	</template>

	<template name="genContent">
		<for-each select="*[self::s:if or self::s:raise or self::s:log or self::s:script or self::s:send or self::s:cancel or self::s:invoke or self::s:finalize or self::s:assign or self::s:validate ]">
			<apply-templates select="."/>
			<if test="not(position() = last())">,</if>
		</for-each>
	</template>

	<template name="genId">
		<param name="s" select="."/>

		<choose>
			<when test="$s/@id">
				"<value-of select="$s/@id"/>"
			</when>
			<when test="$s/@name">
				"<value-of select="$s/@name"/>"
			</when>
			<otherwise>
				"<value-of select="generate-id($s)"/>"
			</otherwise>
		</choose>
	</template>

	<template name="genCond">
		<variable name="cond">
			<choose>
				<when test="@cond">
					<value-of select="@cond"/>
				</when>
				<otherwise>
					<text>true</text>
				</otherwise>
			</choose>
		</variable>

	</template>

	<template match="s:transition">

		<variable name="transitionNum">
			<number level="any" count="s:transition"/>
		</variable>
		<!-- transition id is same as document order. we have it here twice for clarity -->
		{
			"id" : 		<value-of select="$transitionNum - 1"/>,
			"documentOrder" : <value-of select="$transitionNum - 1"/>,
			"source" : 	<call-template name="genId">
						<with-param name="s" select=".."/>
					</call-template>,
			"targets" : 	"<value-of select="@target"/>",
			<if test="@cond">
			"cond" : 	<choose>
						<when test="$wrapCondInFunction">
							function(_event,In){
								return <value-of select="@cond"/>;
							}
						</when>
						<otherwise>
							<call-template name="escapeJsString">
								<with-param name="s" select="@cond"/>
							</call-template>
						</otherwise>
					</choose>,
			</if>
			<if test="@event">
				"event" : 	"<value-of select="@event"/>",
			</if>
			"actions" : 	[<call-template name="genContent"/>]
		}
	</template>

	<!-- gen stuff for executable content. for now i think it's ok to use anonymous functions, but later we'll probably want to move this logic out into an interpreter -->
	<template match="s:if">
		{ 
			"type" : "if",
			"cond" : <call-template name="genCond"/>,
			"actions" : [<call-template name="genContent"/>] 
		}
	</template>

	<template match="s:elseif">
		{ 
			"type" : "elseif",
			"cond" : <call-template name="genCond"/>,
			"actions" : [<call-template name="genContent"/>] 
		}
	</template>

	<template match="s:else">
		{ 
			"type" : "else",
			"actions" : [<call-template name="genContent"/>] 
		}
	</template>

	<template match="s:log">
		{ 
			"type" : "log"
			<if test="@expr">
				,"expr" : <choose>
						<when test="$wrapExprInFunction">
							function(_event,In){
								return <value-of select="@expr"/>;
							}
						</when>
						<otherwise>
							<call-template name="escapeJsString">
								<with-param name="s" select="@expr"/>
							</call-template>
						</otherwise>
					</choose>
			</if>
			
			<if test="@label">
				,"label" : "<value-of select="@label"/>"
			</if>
		}
	</template>

	<template match="s:raise">
	<!--TODO-->
	</template>

	<!-- script module -->

	<template match="s:script">
		{ 
			"type" : "script",
			"script" :  	<choose>
						<when test="$wrapScriptInFunction">
							function(_event,In){
								<value-of select="."/>
							}
						</when>
						<otherwise>
							<call-template name="escapeJsString">
								<with-param name="s" select="text()"/>
							</call-template>
						</otherwise>
					</choose>
		}
	</template>

	<!-- external communications module -->

	<template match="s:send">
		{
			"type" : "send",
			<if test="@delay">
			"delay" : "<value-of select="@delay"/>",
			</if>
			<if test="@id">
			"id" : "<value-of select="@id"/>",
			</if>
			<if test="@contentexpr">
			"contentexpr" : <call-template name="escapeJsString">
						<with-param name="s" select="@contentexpr"/>
					</call-template>,
			</if>
			"event" : "<value-of select="@event"/>"
		}
	</template>

	<template match="s:cancel">
		{ 
			"type" : "cancel",
			"sendid" : "<value-of select="@sendid"/>"
		}
	</template>

	<template match="s:invoke">
	<!--TODO-->
	</template>

	<template match="s:finalize">
	<!--TODO-->
	</template>

	<!-- data module -->

	<template match="s:assign">
		{
			"type" : "assign",
			"location" : "<value-of select="@location"/>",
			"expr" : 	<choose>
						<when test="$wrapExprInFunction">
							function(_event,In){
								return <value-of select="@expr"/>
							}
						</when>
						<otherwise>
							"<value-of select="@expr"/>"	<!-- TODO: escape newline chars (js does not allow multiline strings -->
						</otherwise>
					</choose>
		}
	</template>

	<template match="s:validate">
	<!--TODO-->
	</template>

	<template name="escapeJsString">
		<param name="s"/>

		<variable name="escapedBackSlash">
			<call-template name="searchReplace">
				<with-param name="s" select="$s"/>
				<with-param name="c" select="'\'"/>
				<with-param name="r" select="'\\'"/>
			</call-template>
		</variable>
		<variable name="escapedDoubleQuotes">
			<call-template name="searchReplace">
				<with-param name="s" select="$escapedBackSlash"/>
				<with-param name="c" select="'&quot;'"/>
				<with-param name="r" select="'\&quot;'"/>
			</call-template>
		</variable>
		<variable name="escapedNewlines">
			<call-template name="searchReplace">
				<with-param name="s" select="$escapedDoubleQuotes"/>
				<with-param name="c" select="'&#xA;'"/>
				<with-param name="r" select="'\n'"/>
			</call-template>
		</variable>
		<variable name="escapedTabs">
			<call-template name="searchReplace">
				<with-param name="s" select="$escapedNewlines"/>
				<with-param name="c" select="'&#x9;'"/>
				<with-param name="r" select="'\t'"/>
			</call-template>
		</variable>
		<variable name="escapedCarriageReturn">
			<call-template name="searchReplace">
				<with-param name="s" select="$escapedTabs"/>
				<with-param name="c" select="'&#xD;'"/>
				<with-param name="r" select="'\n'"/>
			</call-template>
		</variable>


		"<value-of select="$escapedCarriageReturn"/>"
	</template>


	<template name="searchReplace">
		<param name="s" /> 
		<param name="c" /> 
		<param name="r" /> 

		<!--
		<message>
			s:<value-of select="$s"/>
			c:<value-of select="$c"/>
			r:<value-of select="$r"/>
		</message>
		-->

		<variable name="string-text" select="string($s)"/>

		<choose>
			<when test="contains($string-text,$c)">

				<!--
				<message>
					first:<value-of select="substring-before($string-text, $c)"/>
					remaining:<value-of select="substring-after($string-text, $c)"/>
				</message>
				-->

				<value-of select="substring-before($string-text, $c)" />
				<value-of select="$r"/> 
				<call-template name="searchReplace">
					<with-param name="s" select="substring-after($string-text, $c)" /> 
					<with-param name="c" select="$c" /> 
					<with-param name="r" select="$r" /> 
				</call-template>
			</when>
			<otherwise>
				<value-of select="$string-text"/>
			</otherwise>
		</choose>

	</template>

	<key name="allEvents" match="s:transition | s:send" use="@event"/>	<!-- used for generating unique list -->

	<template name="genEventsEnum">
		<variable name="uniqueEvents" select="//*[(self::s:transition or self::s:send)][generate-id(.)=generate-id(key('allEvents',@event)[1])]/@event"/>

		{
		<for-each select="$uniqueEvents">
			"<value-of select="."/>" : {
				"name" : "<value-of select="."/>",
				"documentOrder" : <value-of select="position() - 1"/>
			}
			<if test="not(position() = last())">,</if>
		</for-each>	
		}
	</template>

</stylesheet>
