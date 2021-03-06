{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Neuron.Zettelkasten.QuerySpec
  ( spec,
  )
where

import Data.Some
import Data.TagTree
import Neuron.Zettelkasten.ID
import Neuron.Zettelkasten.Query
import Relude
import Test.Hspec
import Text.MMark.MarkdownLink
import Text.URI
import Util

spec :: Spec
spec = do
  describe "Parse zettels by tag URIs" $ do
    let zettelsByTag = Some . Query_ZettelsByTag . fmap mkTagPattern
    it "Parse all zettels URI" $
      parseURIWith queryFromURI "zquery://search" `shouldBe` Right (zettelsByTag [])
    it "Parse single tag" $
      parseURIWith queryFromURI "zquery://search?tag=foo" `shouldBe` Right (zettelsByTag ["foo"])
    it "Parse hierarchical tag" $ do
      parseURIWith queryFromURI "zquery://search?tag=foo/bar" `shouldBe` Right (zettelsByTag ["foo/bar"])
    it "Parse tag pattern" $ do
      parseURIWith queryFromURI "zquery://search?tag=foo/**/bar/*/baz" `shouldBe` Right (zettelsByTag ["foo/**/bar/*/baz"])
    it "Parse multiple tags" $
      parseURIWith queryFromURI "zquery://search?tag=foo&tag=bar"
        `shouldBe` Right (zettelsByTag ["foo", "bar"])
  describe "Parse zettels by ID URI" $ do
    let zid = parseZettelID "1234567"
        zettelById = Some . Query_ZettelByID
    it "parses z:/" $
      queryFromMarkdownLink (mkMarkdownLink "1234567" "z:/")
        `shouldBe` Right (Just $ zettelById zid)
    it "parses z:/ ignoring annotation" $
      queryFromMarkdownLink (mkMarkdownLink "1234567" "z://foo-bar")
        `shouldBe` Right (Just $ zettelById zid)
    it "parses zcf:/" $
      queryFromMarkdownLink (mkMarkdownLink "1234567" "zcf:/")
        `shouldBe` Right (Just $ zettelById zid)
  describe "Parse tags URI" $ do
    it "parses zquery://tags" $
      queryFromMarkdownLink (mkMarkdownLink "." "zquery://tags?filter=foo/**")
        `shouldBe` Right (Just $ Some $ Query_Tags [mkTagPattern "foo/**"])
  describe "short links" $ do
    let shortLink s = mkMarkdownLink s s
        zettelById = Some . Query_ZettelByID
    it "parses date ID" $ do
      queryFromMarkdownLink (shortLink "1234567")
        `shouldBe` Right (Just $ zettelById $ parseZettelID "1234567")
    it "parses custom/hash ID" $ do
      queryFromMarkdownLink (shortLink "foo-bar")
        `shouldBe` Right (Just $ zettelById $ parseZettelID "foo-bar")
    it "even with ?cf" $ do
      queryFromMarkdownLink (shortLink "foo-bar?cf")
        `shouldBe` Right (Just $ zettelById $ parseZettelID "foo-bar")

mkMarkdownLink :: Text -> Text -> MarkdownLink
mkMarkdownLink s l =
  MarkdownLink s $ either (error . toText . displayException) id $ mkURI l
