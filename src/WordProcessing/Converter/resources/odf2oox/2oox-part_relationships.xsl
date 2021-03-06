﻿<?xml version="1.0" encoding="UTF-8"?>
<!--
 * Copyright (c) 2006, Clever Age
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Clever Age nor the names of its contributors 
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:pzip="urn:cleverage:xmlns:post-processings:zip"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
  xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0"
  xmlns:config="urn:oasis:names:tc:opendocument:xmlns:config:1.0"
  xmlns:ooc="urn:odf-converter"
  exclude-result-prefixes="w xlink office draw text style manifest v config ooc">

  <xsl:template name="InsertPartRelationships">
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <!--  Static relationships -->
      <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml" />
      <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml" />
      <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable" Target="fontTable.xml" />
      <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml" />
      <Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footnotes" Target="footnotes.xml" />
      <Relationship Id="rId6" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/endnotes" Target="endnotes.xml" />
      <Relationship Id="rId7" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments" Target="comments.xml" />
      <Relationship Id="CompatibilitySettings" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/customXml" Target="../customXml/CompatibilitySettings.xml" />

      <!-- Headers/Footers relationships -->
      <xsl:call-template name="InsertHeaderFooterRelationships" />

      <!-- OLE objects relationships -->
      <xsl:variable name="allOLEs" select="document('content.xml')/office:document-content/office:body//draw:object-ole | document('content.xml')/office:document-content/office:body//draw:object" />
      <xsl:variable name="allShapes" select="document('content.xml')/office:document-content/office:body//draw:custom-shape 
                                             | document('content.xml')/office:document-content/office:body//draw:ellipse 
                                             | document('content.xml')/office:document-content/office:body//draw:rect 
                                             | document('content.xml')/office:document-content/office:body//draw:line 
                                             | document('content.xml')/office:document-content/office:body//draw:connector
                                             | document('content.xml')/office:document-content/office:body//draw:frame" />

      <xsl:call-template name="InsertOleObjectsRelationships">
        <xsl:with-param name="oleObjects" select="$allOLEs" />
      </xsl:call-template>
      <!-- Sonata:Picture Fill Relationship -->
      <xsl:call-template name="InsertShapesRelationships">
        <xsl:with-param name="shapes" select="$allShapes" />
      </xsl:call-template>
      <!-- Images relationships -->
      <xsl:for-each select="document('content.xml')">
        <xsl:call-template name="InsertImagesRelationships">
          <xsl:with-param name="images" select="key('images', '')[not(ancestor::text:note)]" />
        </xsl:call-template>
      </xsl:for-each>

      <!-- Hyperlinks relationships -->
      <xsl:for-each select="document('content.xml')">
        <xsl:call-template name="InsertHyperlinksRelationships">
          <xsl:with-param name="hyperlinks" select="key('hyperlinks', '')[not(ancestor::text:note)]" />
        </xsl:call-template>
      </xsl:for-each>
    </Relationships>
  </xsl:template>
  <!-- Soanta: Template to create Picture fill relationship -->
  <xsl:template name="InsertShapesRelationships">
    <xsl:param name="shapes" select="." />
    <xsl:for-each select="$shapes">
      <xsl:variable name="shapeRelId" select="generate-id(.)" />
      <xsl:variable name="styleName" select="@draw:style-name" />
      <xsl:variable name="shapeStyle" select="key('automatic-styles', $styleName)" />
      <!-- Sona: Picture fill for a frame-->
      <xsl:choose>
        <xsl:when test="($shapeStyle/@style:parent-style-name) and (self::node()[name()='draw:frame'] or parent::node()[name()='draw:frame'])">
          <xsl:for-each select="$shapeStyle/style:graphic-properties/style:background-image">
            <xsl:if test="@xlink:href !=''">
              <xsl:variable name="imageName">
                <xsl:call-template name="substring-after-last">
                  <xsl:with-param name="string" select="@xlink:href" />
                  <xsl:with-param name="occurrence" select="'/'" />
                </xsl:call-template>
              </xsl:variable>

              <pzip:copy pzip:source="{@xlink:href}" pzip:target="{concat('word/media/', $imageName)}" />
              <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                            Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
                            Id="{concat('Bitmap_',$shapeRelId)}"
                            Target="{concat('media/', $imageName)}" />

            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="$shapeStyle/style:graphic-properties[@draw:fill='bitmap']">
            <xsl:variable name="BitmapName" select="@draw:fill-image-name" />
            <xsl:for-each select="document('styles.xml')/office:document-styles/office:styles/draw:fill-image[@draw:name = $BitmapName]">
              <xsl:if test="@xlink:href !=''">
                <xsl:variable name="imageName">
                  <xsl:call-template name="substring-after-last">
                    <xsl:with-param name="string" select="@xlink:href" />
                    <xsl:with-param name="occurrence" select="'/'" />
                  </xsl:call-template>
                </xsl:variable>

                <pzip:copy pzip:source="{@xlink:href}" pzip:target="{concat('word/media/', $imageName)}" />

                <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                              Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
                              Id="{concat('Bitmap_',$shapeRelId)}"
                              Target="{concat('media/', $imageName)}" />

              </xsl:if>
            </xsl:for-each>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- 
  Summary: inserts the rels for OLEs and copies the internal objects
  Author: makz (DIaLOGIKa)
  Date: 8.11.2007
  -->
  <xsl:template name="InsertOleObjectsRelationships">
    <xsl:param name="oleObjects" />

    <xsl:for-each select="$oleObjects">
      <xsl:variable name="oleFile">
        <!-- MS Office writes links to internal ODF document with a trailing slash -->
        <xsl:choose>
          <xsl:when test="substring(@xlink:href, string-length(@xlink:href)) = '/'">
            <xsl:call-template name="substring-after-last">
              <xsl:with-param name="string" select="substring(@xlink:href, 1, string-length(@xlink:href) - 1)" />
              <xsl:with-param name="occurrence" select="'./'" />
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
<!--OLE,vipul-->

            <xsl:choose>
              <xsl:when test="starts-with(@xlink:href,'ObjectReplacements/' or starts-with(@xlink:href, '..'))">
                <xsl:value-of select="@xlink:href"/>
              </xsl:when>
              <xsl:otherwise>
            <xsl:call-template name="substring-after-last">
              <xsl:with-param name="string" select="@xlink:href" />
              <xsl:with-param name="occurrence" select="'./'" />
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="oleId" select="generate-id(.)" />
      <xsl:variable name="olePicture">
        <xsl:call-template name="substring-after-last">
          <xsl:with-param name="string" select="../draw:image[1]/@xlink:href" />
          <xsl:with-param name="occurrence" select="'./'" />
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="olePictureId" select="generate-id(../draw:image[1])" />
      <xsl:variable name="olePictureType">
        <xsl:call-template name="GetOLEPictureType">
          <xsl:with-param name="olePicture" select="$olePicture" />

          <!--Sonata: Added Parameter oleType:2656673 DOCX - Embedded OLE Object not retained -->
          <xsl:with-param name="oleType">
            <xsl:choose>
              <xsl:when test="starts-with(@xlink:href,'/') or starts-with(@xlink:href,'../') or starts-with(@xlink:href,'//')
                                            or starts-with(@xlink:href,'file:///')">
                <xsl:value-of select="'link'"/>
              </xsl:when>
              <xsl:when test="starts-with(@xlink:href,'./')">
                <xsl:value-of select="'embed'"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'embed'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:variable>

      <xsl:choose>
        <!-- internal OLE -->
        <xsl:when test="not(ooc:IsUriExternal(@xlink:href))">
          <xsl:variable name="oleType" select="document('META-INF/manifest.xml')/manifest:manifest/manifest:file-entry[@manifest:full-path=$oleFile]/@manifest:media-type" />

          <!-- 
            don't insert internal ODF OLEs 
            internal ODF ole's have application type eg.
            application/vnd.oasis.opendocument.spreadsheet
          -->
          <xsl:choose>
            <xsl:when test="$oleType='application/vnd.sun.star.oleobject' or $oleType='application/octet-stream'">
              <pzip:copy pzip:source="{$oleFile}" pzip:target="{concat('word/embeddings/', $oleId, '.bin')}" />
              <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                            Id="{$oleId}"
                            Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/oleObject"
                            Target="{concat('embeddings/', $oleId, '.bin')}"
                            TargetMode="Internal" />

            </xsl:when>
          </xsl:choose>

          <xsl:call-template name="HandleOlePreview">
            <xsl:with-param name="olePicture" select="$olePicture" />
            <xsl:with-param name="olePictureId" select="$olePictureId" />
            <xsl:with-param name="olePictureType" select="$olePictureType" />
          </xsl:call-template>

        </xsl:when>
        <!-- external OLE on network or local drive -->
        <xsl:when test="ooc:IsUriExternal(@xlink:href)">

          <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                        Id="{$oleId}"
                        Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/oleObject"
                        Target="{ooc:UriFromPath(@xlink:href, true())}"
                        TargetMode="External" />

          <xsl:call-template name="HandleOlePreview">
            <xsl:with-param name="olePicture" select="$olePicture" />
            <xsl:with-param name="olePictureId" select="$olePictureId" />
            <xsl:with-param name="olePictureType" select="$olePictureType" />
          </xsl:call-template>

        </xsl:when>

      </xsl:choose>

    </xsl:for-each>
  </xsl:template>

  <!-- 
    Summary: copies the preview image of a OLE object and inserts the relationship
    Author: makz (DIaLOGIKa)
    Date: 9.11.2007
  -->
  <xsl:template name="HandleOlePreview">
    <xsl:param name="olePicture" />
    <xsl:param name="olePictureId" />
    <xsl:param name="olePictureType" />

    <xsl:choose>


      <xsl:when test="$olePictureType='GDIMetaFile'">
        <!-- copy placeholder picture -->
        <pzip:copy pzip:source="#CER#WordprocessingConverter.dll#OdfConverter.Wordprocessing.resources.OLEplaceholder.png#" pzip:target="{concat('word/media/', $olePictureId, '.png')}" />
        <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                      Id="{$olePictureId}"
                      Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
                      Target="{concat('media/', $olePictureId, '.png')}" />
      </xsl:when>
    
      <xsl:when test="not($olePictureType='') and not($olePictureId='')">
        <!-- copy picture -->
        <pzip:copy pzip:source="{$olePicture}" pzip:target="{concat('word/media/', $olePictureId, '.', $olePictureType)}" />
        <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                      Id="{$olePictureId}"
                      Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
                      Target="{concat('media/', $olePictureId, '.', $olePictureType)}" />

      </xsl:when>
      <xsl:when test="not($olePictureId='')">
        <!-- copy placeholder picture -->
        <pzip:copy pzip:source="#CER#WordprocessingConverter.dll#OdfConverter.Wordprocessing.resources.OLEplaceholder.png#" pzip:target="{concat('word/media/', $olePictureId, '.png')}" />
        <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                      Id="{$olePictureId}"
                      Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
                      Target="{concat('media/', $olePictureId, '.png')}" />

      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <!--
  Summary: Returns the type of the image.
  Returns '' if type is not supported
  Author: makz (DIaLOGIKa)
  Date: 9.11.2007
  -->
  <xsl:template name="GetOLEPictureType">
    <xsl:param name="olePicture" />
    <xsl:param name="oleType" />
    
    <xsl:variable name="allManifestEntries" select="document('META-INF/manifest.xml')/manifest:manifest/manifest:file-entry" />
    <xsl:variable name="type" select="$allManifestEntries[@manifest:full-path=$olePicture]/@manifest:media-type" />

    <xsl:choose>
      <xsl:when test="contains($type,'application/x-openoffice-gdimetafile')">
        <xsl:text>GDIMetaFile</xsl:text>
      </xsl:when>
      <xsl:when test="$type=''">
        <xsl:if test="$oleType='link'">
          <xsl:text>GDIMetaFile</xsl:text>
        </xsl:if>
      </xsl:when>
      <!-- picture is a WMF -->
      <xsl:when test="$type='application/x-openoffice-wmf;windows_formatname=&quot;Image WMF&quot;'">
        <xsl:text>wmf</xsl:text>
      </xsl:when>
      <!-- picture is a WMF -->
      <xsl:when test="$type='application/x-openoffice-wmf;windows_formatname=&quot;Image EMF&quot;'">
        <xsl:text>emf</xsl:text>
      </xsl:when>
      <!-- picture is a PNG -->
      <xsl:when test="$type='image/png'">
        <xsl:text>png</xsl:text>
      </xsl:when>
      <!-- picture is a JPG -->
      <xsl:when test="$type='image/jpeg'">
        <xsl:text>jpeg</xsl:text>
      </xsl:when>
      <!--Sonata: 2656673 DOCX - Embedded OLE Object not retained -->
      <xsl:when test="$oleType='embed'">
        <xsl:text>png</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text></xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- Images relationships -->
  <xsl:template name="InsertImagesRelationships">
    <xsl:param name="images" />

    <xsl:for-each select="$images">
      <xsl:variable name="supported">
        <xsl:call-template name="IsImageSupportedByWord">
          <xsl:with-param name="name" select="@xlink:href" />
        </xsl:call-template>
      </xsl:variable>
      <xsl:if test="@xlink:href and $supported = 'true' ">
        <xsl:choose>
          <!-- External IRI (either contains a protocal such as http: or starts with a slash, or a relative IRI pointing outside the package) -->
          <xsl:when test="ooc:IsUriExternal(@xlink:href)">
            <!-- External image : If relative path, image may not be converted. -->
            <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                          Id="{generate-id(.)}"
                          Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
                          Target="{ooc:UriFromPath(@xlink:href)}"
                          TargetMode="External" />

            <xsl:if test="ancestor::draw:a">
              <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                            Id="{generate-id(ancestor::draw:a)}"
                            Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"
                            TargetMode="External"
                            Target="{ooc:UriFromPath(ancestor::draw:a/@xlink:href)}" />
            </xsl:if>
          </xsl:when>
          <!-- Internal image -->
          <xsl:otherwise>
            <!-- copy this image to the oox package -->
            <xsl:variable name="imageName">
              <xsl:call-template name="substring-after-last">
                <xsl:with-param name="string" select="@xlink:href" />
                <xsl:with-param name="occurrence" select="'/'" />
              </xsl:call-template>
            </xsl:variable>

            <pzip:copy pzip:source="{@xlink:href}" pzip:target="{concat('word/media/', $imageName)}" />
            <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                          Id="{generate-id(.)}"
                          Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
                          Target="{concat('media/', $imageName)}" />

            <xsl:if test="ancestor::draw:a">
              <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                            Id="{generate-id(ancestor::draw:a)}"
                            Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"
                            Target="{ooc:UriFromPath(ancestor::draw:a/@xlink:href)}"
                            TargetMode="External" />
                
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- Replacing spaces in paths with %20 -->
  <!--<xsl:template name="HandlingSpaces">
    <xsl:param name="path" />
    <xsl:choose>
      <xsl:when test="contains($path,' ')">
        <xsl:variable name="subPath">
          <xsl:call-template name="HandlingSpaces">
            <xsl:with-param name="path" select="substring-after($path,' ')" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="concat(substring-before($path,' '),'%20',$subPath)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$path" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>-->



  <!-- Hyperlinks relationships -->
  <xsl:template name="InsertHyperlinksRelationships">
    <xsl:param name="hyperlinks" />

    <xsl:for-each select="$hyperlinks">
      <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                    Id="{generate-id()}"
                    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"
                    Target="{ooc:UriFromPath(@xlink:href)}"
                    TargetMode="External" />
    </xsl:for-each>
  </xsl:template>


  <!-- Headers / footers relationships -->
  <xsl:template name="InsertHeaderFooterRelationships">
    <xsl:variable name="masterPages" select="document('styles.xml')/office:document-styles/office:master-styles/style:master-page" />

    <xsl:for-each select="$masterPages/style:header | $masterPages/style:header-left">
      <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                    Id="{generate-id()}"
                    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header"
                    Target="{concat('header', position(), '.xml')}" />
    </xsl:for-each>
    <xsl:for-each select="$masterPages/style:footer | $masterPages/style:footer-left">
      <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                    Id="{generate-id()}"
                    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer"
                    Target="{concat('footer', position(), '.xml')}" />
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
