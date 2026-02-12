<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
    version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
    xmlns:xsdgen="http://clankysoftware.com/namespace/xsdpgen">
    <xsl:output method="xml" indent="yes"/>
    
    <xsl:variable name="schemaPrefix" select="substring-before(/xsd:schema/name(), ':')"/>

    <xsl:template match="xsd:schema">
        <xsl:element name="XsdGenOutput">
            <xsl:apply-templates select="xsd:element"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="xsd:element[@ref]">
        <xsl:variable name="referencedElementName" select="@ref"/>
        <xsl:variable name="referencedElementNode" select="/xsd:schema/xsd:element[@name=$referencedElementName]" />
        
        <xsl:apply-templates select="$referencedElementNode" />
    </xsl:template>
    
    <xsl:template match="xsd:element">
        <xsl:element name="{@name}" namespace="{ancestor::xsd:schema/@targetNamespace}">
            <xsl:call-template name="NodeHandler"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="xsd:attribute">
        <xsl:attribute name="{@name}">
            <xsl:call-template name="NodeHandler"/>
        </xsl:attribute>
    </xsl:template>
    
    
    <xsl:template name="NodeHandler">
        <xsl:choose>
            <xsl:when test="@type">
                <xsl:variable name="referencedTypePrefix" select="substring-before(@type, ':')" />
                <xsl:variable name="referencedTypeNamespace" select="ancestor::xsd:schema/namespace::*[name()=$referencedTypePrefix]" />
                <xsl:variable name = "referencedTypeName">
                    <xsl:variable name="refTest" select="substring-after(@type, ':')"/>
                    <xsl:choose>
                        <xsl:when test="$refTest = ''">
                            <xsl:value-of select="@type"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$refTest"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:choose> 
                    <xsl:when test="$referencedTypePrefix = $schemaPrefix"> <!-- schema namespace types: string, int, etc -->
                        <xsl:value-of select="concat($schemaPrefix,concat(':',$referencedTypeName))"/>
                    </xsl:when>
                    
                    <xsl:when test="ancestor::*/@name=$referencedTypeName">
                        <xsl:value-of select="@name"/>
                        <xsl:comment>Loop-ancestor</xsl:comment>
                    </xsl:when>
                    
                    <xsl:otherwise>
                        <xsl:variable name="referencedTypeSchema" select="/xsd:schema[@targetNamespace=$referencedTypeNamespace]" />
                        <xsl:variable name="referencedTypeNode" select="$referencedTypeSchema/*[(self::xsd:complexType or self::xsd:complexContent or self::xsd:simpleType) and @name=$referencedTypeName]" />
                        <xsl:apply-templates select="$referencedTypeNode"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- Element type is inside element itself (sequence, complextype) -->
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="node()[self::xsd:complexType]|@*[self::xsd:complexType]">
                        <xsl:apply-templates select="node()[self::xsd:complexType]|@*[self::xsd:complexType]"/>
                        <xsl:apply-templates select="node()[not(self::xsd:complexType)]|@*[not(self::xsd:complexType)]"/>
                    </xsl:when>
                    <!-- Default datatype = xsd:string -->
                    <xsl:otherwise>
                        <xsl:text>xsd:string</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="xsd:any">
        <xsl:element name="anyElement" namespace="{/xsd:schema/@targetNamespace}">
            <xsl:apply-templates select="node()|@*"/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="xsd:documentation">
        <!-- Best solution to the indent problem i could find is to add linebreaks and lint later in VSCode-->
        <xsl:text>&#10;</xsl:text>
        <xsl:comment><xsl:value-of select="."/></xsl:comment>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>
    
    
    <xsl:template match="xsd:extension[@base]">
        <xsl:apply-templates select="node()|@*"/>
        <xsl:value-of select="@base"/>
    </xsl:template>
    
    <xsl:template match="xsd:sequence|xsd:annotation|xsd:complexContent|xsd:choice|xsd:simpleType">
        <xsl:apply-templates select="node()|@*"/>
    </xsl:template>

    <xsl:template match="xsd:simpleContent">
        <xsl:apply-templates select="node()|@*"/>
    </xsl:template>
    
    <xsl:template match="xsd:simpleType[not(xsd:restriction)]">
        <xsl:apply-templates select="node()|@*"/>
        <xsl:text>?</xsl:text>
    </xsl:template>
    
    <xsl:template match="xsd:complexType[xsd:attribute]">
        <xsl:apply-templates select="@*"/>
        <xsl:apply-templates select="xsd:attribute"/>
        <xsl:apply-templates select="node()[not(self::xsd:attribute)]"/>
    </xsl:template>

    <xsl:template match="xsd:complexType[not(xsd:attribute)]">
        <xsl:apply-templates select="node()|@*"/>
    </xsl:template>
    
    <xsl:template match="xsd:complexType[xsd:simpleContent]">
        <xsl:apply-templates select="node()|@*"/>
    </xsl:template>

    <xsl:template match="xsd:complexType[not(*)]">
        <xsl:text>string</xsl:text>
    </xsl:template>
    
    <!-- Enumerations to value -->
    <xsl:template match="xsd:restriction">
        <xsl:for-each select="*[self::xsd:enumeration or self::xsd:pattern]">
            <xsl:if test="position() > 1">
                <xsl:text> or </xsl:text>
            </xsl:if>
            <xsl:value-of select="@value"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="node()|@*">
        <xsl:apply-templates select="node()|@*"/>
    </xsl:template>
    
</xsl:stylesheet>
