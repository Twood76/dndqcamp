import 'package:flutter/material.dart';

import 'package:dnd_headlines/app/DndHeadlinesApp.dart';
import 'package:dnd_headlines/models/HeadlineResponse.dart';
import 'package:dnd_headlines/res/Strings.dart';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'package:newsapi_client/newsapi_client.dart';

void main() => runApp(DndHeadlinesRootWidget());

class DndHeadlinesRootWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Strings.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder<RemoteConfig>(
        future: setupRemoteConfig(),
        builder: (BuildContext context, AsyncSnapshot<RemoteConfig> snapshot) {
          return snapshot.hasData
              ? WelcomeWidget(remoteConfig: snapshot.data)
              : Container();
        }
      ),
    );
  }

}

Future<RemoteConfig> setupRemoteConfig() async {
  final RemoteConfig remoteConfig = await RemoteConfig.instance;

  /// Enables developer mode to relax fetch throttling.
  remoteConfig.setConfigSettings(RemoteConfigSettings(debugMode: true));
  remoteConfig.setDefaults(<String, dynamic>{
    Strings.newsApiKey: 'Error',
  });
  return remoteConfig;
}

class WelcomeWidget extends AnimatedWidget {
  WelcomeWidget({this.remoteConfig}) : super(listenable: remoteConfig);

  final RemoteConfig remoteConfig;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.appName),
      ),
      body: Center(child: Text('Hello world!')), /// TODO: Replace with a ListView widget
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.refresh),
          onPressed: () async {
            try {

              /// Using default duration to force fetching from remote server.
              await remoteConfig.fetch(expiration: const Duration(seconds: 0));
              await remoteConfig.activateFetched();
              
              var apiKey = remoteConfig.getString(Strings.newsApiKey);
              var client = NewsapiClient(apiKey);
              await getNewsSources(client);

            } on FetchThrottledException catch (exception) {
              /// Fetch throttled.
              print(exception);
            } catch (exception) {
              print(
                  'Unable to fetch remote config. Cached or default values will be '
                  'used');
            }
          }),
    );
  }
}

Future<Map<String, dynamic>> getNewsSources(NewsapiClient client) async {
  var sourceList = ["bbc-news"];

  /// JSON decoding occurs deep under the hood within the
  /// following.
  final response = await client.request(TopHeadlines(
    sources: sourceList,
    pageSize: 3 /// TODO: Temp
  ));
  var headline = HeadlineResponse.fromJson(response);
  print(headline);

  return response;
}